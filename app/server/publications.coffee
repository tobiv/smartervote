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

Meteor.publish "questions", ->
  Questions.find()

Meteor.publish "visits", ->
	return unless onlyIfUser.call(@)
	Visits.find
		userId:	@userId

Meteor.publishComposite 'answers', ->
  find: ->
    Visits.find
      userId: @userId
  children: [
    find: (visit) ->
      Answers.find
        visitId: visit._id
  ]
