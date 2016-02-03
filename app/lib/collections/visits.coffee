class @Visit
  constructor: (doc) ->
    _.extend this, doc

  scoredDoc: ->
    total = 0
    pro = 0
    Answers.find
      visitId: @_id
    .forEach (answer) ->
      question = Questions.findOne answer.questionId
      a = 2*Math.PI*Math.pow(answer.radius, 2)
      total += a
      if answer.value > 0
        pro += a
      return
    proPercent = 100*pro/total
    proPercent = 0 if total is 0
    proPercent = Math.round(proPercent)
    @proPercent = proPercent
    @


@Visits = new Meteor.Collection("visits",
  transform: (doc) ->
    new Visit(doc)
)

Visits.before.insert BeforeInsertTimestampHook
Visits.before.update BeforeUpdateTimestampHook

Meteor.methods
  "createVisit": ->
    throw new Meteor.Error(400, "you need to log in to init a visit") unless Meteor.userId()?

    visit =
      userId: Meteor.userId()
      completed: false

    _id = Visits.insert visit
    _id


  "saveVisitPNG": (visitId, png) ->
    throw new Meteor.Error(400, "you need to login to reset a visit") unless Meteor.userId()?

    visit = Visits.findOne
      _id: visitId
      userId: Meteor.userId()
    throw new Meteor.Error(400, "visit not found") unless visit?

    Visits.update
      _id: visitId
    ,
      $set:
        png: png

    return

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

  "deleteAllVisits": ->
    throw new Meteor.Error(400, "you need to login") unless Meteor.userId()?
    throw new Meteor.Error(403, "admin privileges required") unless Roles.userIsInRole(Meteor.userId(), 'admin')
    Answers.remove({})
    Visits.remove({})
