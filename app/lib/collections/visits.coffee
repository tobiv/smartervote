class @Visit
  constructor: (doc) ->
    _.extend this, doc

  proPercent: ->
    answers = Answers.find(
      visitId: @_id
    ).fetch()
    Answer.getProPercent(answers)


@Visits = new Meteor.Collection("visits",
  transform: (doc) ->
    new Visit(doc)
)

Visits.before.insert BeforeInsertTimestampHook
Visits.before.update BeforeUpdateTimestampHook

Visits.allow
  update: (userId, doc, fieldNames, modifier) ->
    if Roles.userIsInRole userId, ['admin']
      return true
    false


Meteor.methods
  "createVisit": ->
    throw new Meteor.Error(400, "you need to log in to init a visit") unless Meteor.userId()?

    visit =
      userId: Meteor.userId()
      completed: false

    _id = Visits.insert visit
    _id


  "resetVisit": (visitId) ->
    throw new Meteor.Error(400, "you need to login to reset a visit") unless Meteor.userId()?
    check visitId, String

    visit = Visits.findOne
      _id: visitId
      userId: Meteor.userId()
    throw new Meteor.Error(400, "visit not found") unless visit?

    answerCount = Answers.find(
      visitId: visit._id
    ).count()

    id = Meteor.call "createVisit"

    if answerCount < 5
      Visits.remove visit._id

    return id
