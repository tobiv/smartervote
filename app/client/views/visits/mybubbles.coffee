Template.myBubbles.helpers
  visit: ->
    #we subscribe to only one in route
    Visits.findOne()
