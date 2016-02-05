Template.evaluation.rendered = ->
  @$("#question").mCustomScrollbar({ theme: 'minimal-dark' })

  #render SVG as PNG
  return if !_network?
  svgElementId = _network.getSVGElementId()
  bubblesSVG = d3.select('#'+svgElementId)
    .attr('version', 1.1)
    .attr('xmlns', 'http://www.w3.org/2000/svg')
    .node()
  if !bubblesSVG
    return
  svgAsXML = bubblesSVG.parentNode.innerHTML
  width = _network.width()
  height = _network.height()
  #scale aspect
  maxWidth = 1024
  maxHeight = 768
  if width > maxWidth
    height = maxWidth/width*height
    width = maxWidth
  if height > maxHeight
    width = maxHeight/height*width
    height = maxHeight

  canvas = document.createElement('canvas')
  ctx = canvas.getContext('2d')
  loader = new Image
  loader.width = canvas.width = width
  loader.height = canvas.height = height

  loader.onload = ->
    ctx.drawImage loader, 0, 0, loader.width, loader.height
    pngData = canvas.toDataURL()
    $('#mybubbles-preview').attr 'src', pngData

    visitId = Session.get('visitId')
    if visitId?
      Meteor.call "saveVisitPNG", visitId, pngData, (error) ->
        throwError error if error?
    return

  loader.src = 'data:image/svg+xml,' + encodeURIComponent(svgAsXML)

Template.evaluation.helpers
  visit: ->
    v = Visits.findOne Session.get('visitId')
    v.scoredDoc() if v?

  showCreateAccount: ->
    user = Meteor.user()
    user and (not user.emails or user.emails.length is 0)

  shareData: ->
    title: 'smarterVote'
		url: 'https://bge.patpat.org/myBubbles'+Session.get('visitId')
    #image: ->
    #  "https://pbs.twimg.com/media/CZKmfWBUgAAnubV.jpg:large"


Template.evaluation.events
  "click #gotoQuestions": (evt) ->
    Session.set 'showEvaluation', false
