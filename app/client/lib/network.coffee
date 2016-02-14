class @Network
  constructor: (ele, rMax) ->
    @element = ele
    @radiusMax = rMax

    #init instance vars
    @svgElementId = 'bubblesSVG'
    @width = $(@element).width()
    @height = $(@element).height()

    @svg = d3.select(@element).append("svg")
      .attr('id', @svgElementId)
      .attr("width", @width)
      .attr("height", @height)
      .attr('pointer-events', 'all')
      .attr('xmlns', 'http://www.w3.org/2000/svg')
      .attr('xmlns:xlink', "http://www.w3.org/1999/xlink")
      .attr('version', "1.1")
      #.attr('viewBox', '0 0 ' + @width + ' ' + @height)
      #.attr('viewBox', '0 0 800 600')
      #.attr('perserveAspectRatio', 'xMinYMid')

    @linksG = @svg.append("g").attr("id", "links")
    @nodesG = @svg.append("g").attr("id", "nodes")

    @force = d3.layout.force()
    @drag = @force.drag()

    @nodes = @force.nodes()
    @links = @force.links()

    @_onNodeClick = null
    @_onNodeHover = null


  update: ->
    onNodeClick = @_onNodeClick
    onNodeHover = @_onNodeHover
    node = @nodesG.selectAll("g.node").data(@nodes, (d) -> d.id)
    nodeEnter = node.enter().append("g")
      .on("click", (d) -> onNodeClick(d) if onNodeClick?)
      .on("mouseover", (d) -> onNodeHover(d) if onNodeHover?)
      .on("mouseout", (d) -> onNodeHover(null) if onNodeHover?)
      .call(@drag)
    nodeEnter.append("circle") #image
    nodeEnter.append("image")

    node
      .attr("class", (d) -> if d.classes? then "node "+d.classes else "node")
    node.selectAll('circle')
      .style("fill", (d) -> d.fillColor)
      .style("fill-opacity", (d) -> if d.fillOpacity? then d.fillOpacity else 1.0)
      .style("stroke", (d) -> d.strokeColor)
      .style("stroke-width", (d) -> d.strokeWidth)

    if @animateRadiusChange
      node.selectAll('circle')
        .transition()
        .duration(1200)
          .attr("r", (d) -> d.radius)
    else
      node.selectAll('circle')
        .attr("r", (d) -> d.radius)

    #TODO only append image if isFavorite and remove again
    #node.filter( (d) -> d.isFavorite ).selectAll('g.node')
    #  .append("image").attr("xlink:href","/img/icon-star-active.svg")
    #node.filter( (d) -> !d.isFavorite ).selectAll('image')
    #  .remove("image")

    node.selectAll('image')
      .attr("xlink:href", (d) -> d.image if d.image?)
      .attr("width", (d) -> if d.imageWidth? then d.imageWidth else 0)
      .attr("height", (d) -> if d.imageWidth? then d.imageWidth else 0)
      .attr("x", (d) -> if d.imageX? then d.imageX else 0)
      .attr("y", (d) -> if d.imageY? then d.imageY else 0)

    node.exit().remove()

    link = @linksG.selectAll("line.link").data(@links, (d) -> d.id)
    link.enter().append("line")
      .attr("class", "link")
      .attr("stroke", (d) -> d.strokeColor)#"#ddd")
      .style("stroke-width", (d) -> d.strokeWidth)#1.5)
      #.attr("stroke", (d) -> "#ddd")
      #.style("stroke-width", (d) -> 1.5)
      .attr("stroke-opacity", 0.8)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)
    link
      .attr("linkDistance", (d) -> d.linkDistance)
    link.exit().remove()

    collide = @collide
    nodes = @nodes
    radiusMax = @radiusMax
    width = @width
    height = @height
    @force.on 'tick', ->
      now = Date.now()
      node
        .each(collide(.5, nodes, radiusMax))
        .attr("transform", (d) ->
          #x with respect to width
          d.x = Math.max(d.radius, Math.min(width - d.radius, d.x))
          #honour xMax
          if d.xMax? and d.xMaxT < now and (d.x+d.radius/2) > d.xMax
            d.x = d.xMax-d.radius/2
          d.y = Math.max(d.radius, Math.min(height - d.radius, d.y))
          "translate( #{d.x}, #{d.y} )"
        )
        #.attr("cx", (d) ->
        #  #x with respect to width
        #  d.x = Math.max(d.radius, Math.min(width - d.radius, d.x))
        #  #honour xMax
        #  if d.xMax? and d.xMaxT < now and (d.x+d.radius/2) > d.xMax
        #    d.x = d.xMax-d.radius/2
        #  d.x
        #)
        #.attr("cy", (d) ->
        #  #y with respect to height
        #  d.y = Math.max(d.radius, Math.min(height - d.radius, d.y))
        #)

      link
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)
      return

    # Restart the force layout.
    @force
      .size([ @width, @height ])
      .gravity(.0)
      .charge(-100)
      .linkDistance( (d) -> d.linkDistance )
      .friction(0.4)
      .start()
    return

  onNodeClick: (f) ->
    @_onNodeClick = f
  onNodeHover: (f) ->
    @_onNodeHover = f

  findNode: (id) ->
    for i of @nodes
      if @nodes[i]['id'] == id
        return @nodes[i]
    return

  findNodeIndex: (id) ->
    i = 0
    while i < @nodes.length
      if @nodes[i].id == id
        return i
      i++
    return

  findLinkIndex: (id) ->
    i = 0
    while i < @links.length
      if @links[i].id == id
        return i
      i++
    return

  addNode: (node) ->
    check node.id, String
    @nodes.push node
    @update()
    return

  changeNode: (node) ->
    check node.id, String
    n = @nodes[@findNodeIndex(node.id)]
    if n?
      n.radius = node.radius if node.radius?
      n.fillColor = node.fillColor if node.fillColor?
      n.fillOpacity = node.fillOpacity if node.fillOpacity?
      n.strokeWidth = node.strokeWidth if node.strokeWidth?
      n.strokeColor = node.strokeColor if node.strokeColor?
      n.x = node.x if node.x?
      n.y = node.y if node.y?
      n.px = node.px if node.px?
      n.py = node.py if node.py?
      n.fixed = node.fixed if node.fixed?
      if n.fixed? and n.fixed is true
        n.x = n.px
        n.y = n.py
      n.xMax = node.xMax if node.xMax?
      n.xMaxT = node.xMaxT if node.xMaxT?
      if node.removeXMax
        delete n.xMax
        delete n.xMaxT
      n.classes = node.classes if node.classes?
      if node.removeClasses
        delete n.classes
      if node.isFavorite?
        if node.isFavorite
          n.isFavorite = true
          n.image = 'data:image/svg+xml;base64,PHN2ZyBpZD0ic3RhciIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMjcgMjYiPjxkZWZzPjxzdHlsZT4uYXtmaWxsOiNmZmY7fTwvc3R5bGU+PC9kZWZzPjx0aXRsZT5pY29uLXN0YXItd2hpdGU8L3RpdGxlPjxwYXRoIGNsYXNzPSJhIiBkPSJNMTMuNSwwLjE2TDkuMzMsOC42MSwwLDEwbDYuNzUsNi41OEw1LjE2LDI1Ljg0bDguMzQtNC4zOSw4LjM0LDQuMzktMS41OS05LjI5TDI3LDEwLDE3LjY3LDguNjFaIi8+PC9zdmc+'
          n.imageWidth = 20
          n.imageHeight = 20
          n.imageX = -10
          n.imageY = -10.5
        else
          n.isFavorite = false
      if node.isDead? and not n.isFavorite
        if node.isDead
          n.isDead = true
          n.image = 'data:image/svg+xml;base64,PHN2ZyBpZD0iZGVhZFF1ZXN0aW9uIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MCA2Ij48ZGVmcz48c3R5bGU+LmF7ZmlsbDojZmZmO308L3N0eWxlPjwvZGVmcz48dGl0bGU+aWNvbi1kZWFkUXVlc3Rpb248L3RpdGxlPjxyZWN0IGNsYXNzPSJhIiB3aWR0aD0iNTAiIGhlaWdodD0iNiIvPjwvc3ZnPg==' 
          n.imageWidth = 40
          n.imageHeight = 20
          n.imageX = -20
          n.imageY = -20
        else
          n.isDead = false
      if !n.isDead and !n.isFavorite
        delete n.image
      if node.hoverable?
        if node.hoverable
          n.hoverable = true
        else
          delete n.hoverable

      @update()
    else
      console.log "Network changeNode: node (#{node.id}) not found"
    return

  removeNode: (id) ->
    i = 0
    n = @findNode(id)
    while i < @links.length
      if @links[i]['source'] == n or @links[i]['target'] == n
        @links.splice i, 1
      else
        i++
    @nodes.splice @findNodeIndex(id), 1
    @update()
    return

  addLink: (link) ->
    check link.sourceId, String
    check link.targetId, String
    check link.linkDistance, Number
    link = _.extend link,
      id: "#{link.sourceId}__#{link.targetId}"
      'source': @findNode(link.sourceId)
      'target': @findNode(link.targetId)
    check link.source, Object
    check link.target, Object
    link = _.omit link, ['sourceId', 'targetId']
    @links.push link
    @update()
    return

  changeLink: (link) ->
    check link.sourceId, String
    check link.targetId, String
    l = @links[@findLinkIndex("#{link.sourceId}__#{link.targetId}")]
    l.linkDistance = link.linkDistance
    @update()
    return

  removeLink: (link) ->
    check link.sourceId, String
    check link.targetId, String
    i = @findLinkIndex("#{link.sourceId}__#{link.targetId}")
    if i?
      @links.splice i, 1
    @update()
    return

  removeAllLinks: ->
    @links.length = 0
    @update()
    return

  removeAllNodes: ->
    @nodes.length = 0
    @update()
    return

  resize: ->
    @width = $(@element).width()
    @height = $(@element).height()
    svg = $('#'+@svgElementId).get(0)
    #svg.setAttribute 'viewBox', "0 0 #{w} #{h}"
    svg.setAttribute 'width', @width
    svg.setAttribute 'height', @height
    @update()

  getElement: ->
    @element

  appendGradient: (id, c0, c1) ->
    gradient = @svg.append("defs")
      .append("linearGradient")
        .attr("id", id)
    gradient.append("stop")
      .attr("offset", "0%")
      .attr("stop-color", c0)
    gradient.append("stop")
      .attr("offset", "100%")
      .attr("stop-color", c1)

  setRadiusMax: (rMax) ->
    @radiusMax = rMax

  # Resolves collisions between d and all other circles.
  # http://stackoverflow.com/questions/11339348/avoid-d3-js-circles-overlapping
  collide: (alpha, nodes, radiusMax) ->
    padding = 5 #separation between same-color circles
    clusterPadding = 6 #separation between different-color circles

    quadtree = d3.geom.quadtree(nodes)
    (d) ->
      r = d.radius + radiusMax + Math.max(padding, clusterPadding)
      nx1 = d.x - r
      nx2 = d.x + r
      ny1 = d.y - r
      ny2 = d.y + r
      quadtree.visit (quad, x1, y1, x2, y2) ->
        `var r`
        if quad.point and quad.point != d
          x = d.x - (quad.point.x)
          y = d.y - (quad.point.y)
          l = Math.sqrt(x * x + y * y)
          r = d.radius + quad.point.radius + (if d.cluster == quad.point.cluster then padding else clusterPadding)
          if l < r
            l = (l - r) / l * alpha
            d.x -= x *= l
            d.y -= y *= l
            quad.point.x += x
            quad.point.y += y
        x1 > nx2 or x2 < nx1 or y1 > ny2 or y2 < ny1
      return
