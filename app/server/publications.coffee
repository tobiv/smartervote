onlyIfAdmin = ->
  if Roles.userIsInRole(@userId, ['admin'])
    return true
  else
    @ready()
    return

onlyIfUser = ->
  if @userId
    return true
  else
    @ready()
    return

######################################

Meteor.publish "users", ->
  return unless onlyIfAdmin.call(@)
  Meteor.users.find({},
    fields:
      _id: 1
      username: 1
      emails: 1
      profile: 1
      roles: 1
      status: 1
      createdAt: 1
  )

Meteor.publish "questions", (lang) ->
  Questions.find( {},
    fields:
      _id: 1
      index: 1
      cluster: 1
      topic: 1
      isOneSided: 1
      isOnlyNegative: 1
      isLeftPositiv: 1
      min: 1
      max: 1
      "languages.#{lang}.label": 1
      "languages.#{lang}.minLabel": 1
      "languages.#{lang}.maxLabel": 1
      "languages.#{lang}.info": 1
  )



Meteor.publish "visits", ->
	return unless onlyIfUser.call(@)
	Visits.find
		userId:	@userId

Meteor.publish "visit", (id)->
  Visits.find
    _id: id
  ,
    fields:
      _id: 1
      myBubblesUrl: 1

Meteor.publishComposite 'visitAndAnswers', (visitId) ->
  find: ->
    Visits.find
      _id: visitId
    ,
      fields:
        _id: 1
        myBubblesUrl: 1
  children: [
    find: (visit) ->
      Answers.find
        visitId: visit._id
  ]

Meteor.publishComposite 'answers', ->
  find: ->
    Visits.find
      userId: @userId
  children: [
    find: (visit) ->
      Answers.find
        visitId: visit._id
  ]
