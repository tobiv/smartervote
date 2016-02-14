Template.smartervoteAdmin.helpers
  visits: ->
    Visits.find()

  email: ->
    user = Meteor.users.findOne
      _id: @userId
    user.emails[0].address if user?

  nameEO: ->
    visit = @
    value: visit.name
    emptytext: "no name"
    success: (response, newVal) ->
      Visits.update visit._id,
        $set: {name: newVal}
      return

Template.smartervoteAdmin.events
  'click .publish': (evt) ->
    Visits.update @_id,
      $set: 
        isPublished: true
        savedProPercent: @proPercent()

  'click .unpublish': (evt) ->
    Visits.update @_id,
      $set: {isPublished: false}
