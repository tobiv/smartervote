class @Network
  width = 800
  height = 600

  # these will hold the svg groups for
  # accessing the nodes and links display
  nodesG = null
  linksG = null

  force = null
  drag = null

  nodes = null
  links = null

  color = null

  constructor: (element) ->
    width = $(".left").width()
    height = $(window).height()

    vis = d3.select(element).append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr('pointer-events', 'all')
      .attr('viewBox', '0 0 ' + width + ' ' + height)
      .attr('perserveAspectRatio', 'xMinYMid')

    linksG = vis.append("g").attr("id", "links")
    nodesG = vis.append("g").attr("id", "nodes")

    force = d3.layout.force()

    drag = force.drag()
      .on("dragstart", @dragstart)

    nodes = force.nodes()
    links = force.links()

    color = d3.scale.category20()


  update: ->
    node = nodesG.selectAll("circle.node").data(nodes, (d) -> d.id)
    node.enter().append("circle")
      .attr("class", "node")
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .attr("r", (d) -> 16)#d.radius)
      .style("fill", (d) -> color(1/d.rating) )
      .style("stroke-width", 0)
      .on("dblclick", @dblclick)
      .call(drag)
    node.exit().remove()

    link = linksG.selectAll("line.link").data(links, (d) -> d.id)
    #  .data(links, (d) -> "#{d.source.id}_#{d.target.id}")
    link.enter().append("line")
      .attr("class", "link")
      .attr("stroke", "#ddd")
      .attr("stroke-opacity", 0.8)
      .style("stroke-width", 1.0)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)
    link.exit().remove()

    force.on 'tick', ->
      node
      	.attr("cx", (d) -> d.x)
      	.attr("cy", (d) -> d.y)
      #node.attr 'transform', (d) ->
      #  'translate(' + d.x + ',' + d.y + ')'

      link
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)
      return

    # Restart the force layout.
    force.gravity(.03)
      .distance(50)
      .linkDistance(100)
      .charge(-80)
      .size([ width, height ])
      .start()
    return

  dblclick: (d) ->
    d3.select(@).classed("fixed", d.fixed = false)

  dragstart: (d) ->
    d3.select(@).classed("fixed", d.fixed = true)

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

  addNode: (node) ->
    check node.id, String
    console.log node
    nodes.push node
    @update()
    return

  removeNode: (id) ->
    i = 0
    n = findNode(id)
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
    check link.value, Number
    console.log link
    link = _.extend link,
      id: "#{link.sourceId}_#{link.targetId}"
      'source': @findNode(link.sourceId)
      'target': @findNode(link.targetId)
    link = _.omit link, ['sourceId', 'targetId']
    check link.source, Object
    check link.target, Object
    links.push link
    @update()
    return

  removeLink: (id) ->
    i = 0
    while i < links.length
      if links[i].id == id
        links.splice i, 1
        break
      i++
    @update()
    return

  removeallLinks: ->
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
