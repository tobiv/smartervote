class @Network
  element = null
  width = null
  height = null

  # these will hold the svg groups for
  # accessing the nodes and links display
  nodesG = null
  linksG = null

  force = null
  drag = null

  nodes = null
  links = null

  radiusMax = null

  constructor: (ele, rMax) ->
    element = ele
    radiusMax = rMax

    width = $(element).width()
    height = $(element).height()
    #height = $(window).height()-45
    #width = 640 if width < 640
    #height = 800 if height < 800

    vis = d3.select(element).append("svg")
      .attr('id', 'bubblesSVG')
      .attr("width", width)
      .attr("height", height)
      .attr('pointer-events', 'all')
      #.attr('viewBox', '0 0 ' + width + ' ' + height)
      #.attr('viewBox', '0 0 800 600')
      #.attr('perserveAspectRatio', 'xMinYMid')

    linksG = vis.append("g").attr("id", "links")
    nodesG = vis.append("g").attr("id", "nodes")

    force = d3.layout.force()

    drag = force.drag()
      .on("dragstart", @dragstart)

    nodes = force.nodes()
    links = force.links()


  update: ->
    node = nodesG.selectAll("circle.node").data(nodes, (d) -> d.id)
    nodeEnter = node.enter()
    nodeEnter.append("circle") #image
      .attr("class", "node")
      #.attr("x", -50)#(d) -> d.x)
      #.attr("y", -50)#(d) -> d.y)
      #.attr("width", 100)#(d) -> 100)
      #.attr("height", 100)#(d) -> 100)
      #.attr("xlink:href", (d) -> "http://cdn-img.people.com/emstag/i/2012/pets/gallery/icancheeze/120116/new-year-660.jpg")
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .style("stroke-width", 0)
      .on("dblclick", @dblclick)
      .on("click", @click)
      .on("mouseover", @mouseover)
      .on("mouseout", @mouseout)
      .call(drag)
    #nodeEnter.append("text")
    #  .attr("dx", (d) -> d.x)
    #  .attr("dy", (d) -> d.y)
    #  .text( (d) -> d.id )
    node
      .attr("r", (d) -> d.radius)
      .style("fill", (d) -> d.fillColor)
      .attr("stroke", (d) -> d.strokeColor)
      .style("stroke-width", (d) -> d.strokeWidth)
    node.exit().remove()

    link = linksG.selectAll("line.link").data(links, (d) -> d.id)
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
    force.on 'tick', ->
      node
        .each(collide(.5))
        .attr("cx", (d) -> d.x = Math.max(d.radius, Math.min(width - d.radius, d.x)))
        .attr("cy", (d) -> d.y = Math.max(d.radius, Math.min(height - d.radius, d.y)))
      #node.attr 'transform', (d) ->
      #  'translate(' + d.x + ',' + d.y + ')'

      link
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)
      return

    # Restart the force layout.
    force
      .size([ width, height ])
      .gravity(.0)
      .charge(-100)
      .linkDistance( (d) -> d.linkDistance )
      #.friction(0.1)
      .start()
    return

  _onNodeClick = null
  onNodeClick: (f) ->
    _onNodeClick = f

  _onNodeHover = null
  onNodeHover: (f) ->
    _onNodeHover = f

  click: (d) ->
    _onNodeClick(d) if _onNodeClick?

  dblclick: (d) ->
    d3.select(@).classed("fixed", d.fixed = false)

  mouseover: (d) ->
    _onNodeHover(d) if _onNodeHover?
  mouseout: (d) ->
    _onNodeHover(null) if _onNodeHover?

  dragstart: (d) ->
    # no fixing for now
    #d3.select(@).classed("fixed", d.fixed = true)

  findNode: (id) ->
    for i of nodes
      if nodes[i]['id'] == id
        return nodes[i]
    return

  findNodeIndex: (id) ->
    i = 0
    while i < nodes.length
      if nodes[i].id == id
        return i
      i++
    return

  findLinkIndex: (id) ->
    i = 0
    while i < links.length
      if links[i].id == id
        return i
      i++
    return

  addNode: (node) ->
    check node.id, String
    nodes.push node
    @update()
    return

  changeNode: (node) ->
    check node.id, String
    n = nodes[@findNodeIndex(node.id)]
    n.radius = node.radius if node.radius?
    n.fillColor = node.fillColor if node.fillColor?
    n.strokeWidth = node.strokeWidth if node.strokeWidth?
    n.strokeColor = node.strokeColor if node.strokeColor?
    n.x = node.x if node.x?
    n.y = node.y if node.y?
    n.px = node.px if node.px?
    n.py = node.py if node.py?
    n.fixed = node.fixed if node.fixed?
    @update()
    return

  removeNode: (id) ->
    i = 0
    n = @findNode(id)
    while i < links.length
      if links[i]['source'] == n or links[i]['target'] == n
        links.splice i, 1
      else
        i++
    nodes.splice @findNodeIndex(id), 1
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
    link = _.omit link, ['sourceId', 'targetId']
    check link.source, Object
    check link.target, Object
    links.push link
    @update()
    return

  changeLink: (link) ->
    check link.sourceId, String
    check link.targetId, String
    l = links[@findLinkIndex("#{link.sourceId}__#{link.targetId}")]
    l.linkDistance = link.linkDistance
    @update()
    return

  removeLink: (link) ->
    check link.sourceId, String
    check link.targetId, String
    i = @findLinkIndex("#{link.sourceId}__#{link.targetId}")
    if i?
      links.splice i, 1
    @update()
    return

  removeAllLinks: ->
    links.splice 0, links.length
    @update()
    return

  removeAllNodes: ->
    nodes.splice 0, links.length
    @update()
    return

  width: ->
    width

  height: ->
    height

  resize: () ->
    width = $(element).width()
    height = $(element).height()
    svg = $('#bubblesSVG').get(0)
    #svg.setAttribute 'viewBox', "0 0 #{w} #{h}"
    svg.setAttribute 'width', width
    svg.setAttribute 'height', height
    @update()

  
  # Resolves collisions between d and all other circles.
  # http://stackoverflow.com/questions/11339348/avoid-d3-js-circles-overlapping
  collide: (alpha) ->
    padding = 5 #separation between same-color circles
    clusterPadding = 6 #separation between different-color circles
    maxRadius = radiusMax

    quadtree = d3.geom.quadtree(nodes)
    (d) ->
      r = d.radius + maxRadius + Math.max(padding, clusterPadding)
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

