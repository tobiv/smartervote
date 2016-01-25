Template.score.rendered = ->
  html = d3.select('svg')
    .attr('version', 1.1)
    .attr('xmlns', 'http://www.w3.org/2000/svg')
    .node().parentNode.innerHTML
  imgsrc = 'data:image/svg+xml;base64,' + btoa(html)
  @$('#smarterBubbles').attr 'src', imgsrc

Template.score.helpers
  showCreateAccount: ->
    user = Meteor.user()
    user and (not user.emails or user.emails.length is 0)

  proPercent: ->
    0#_proPercent.get()

  shareData: ->
    title: 'smarterVote'
		url: 'bge.patpat.org'
		image: ->
      "https://pbs.twimg.com/media/CZKmfWBUgAAnubV.jpg:large"
			

Template.score.events
  "click #gotoQuestions": (evt) ->
    Session.set 'showScore', false
