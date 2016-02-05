class @Answer
  constructor: (doc) ->
    _.extend this, doc

  @getProPercent: (answers) ->
    total = 0
    pro = 0
    answers.forEach (answer) ->
      if answer.status is 'valid'
        a = 2*Math.PI*Math.pow(answer.radius, 2)
        total += a
        if answer.value > 0
          pro += a
      return
    proPercent = 100*pro/total
    proPercent = 0 if total is 0
    proPercent = Math.round(proPercent)
    proPercent

@Answers = new Meteor.Collection("answers",
  transform: (doc) ->
    new Answer(doc)
)

Answers.before.insert BeforeInsertTimestampHook
Answers.before.update BeforeUpdateTimestampHook

#if Meteor.isServer #because of Meteor.call "createVisit"
Meteor.methods
  "upsertAnswer": (answer) ->
    check(answer.questionId, String)

    #if Meteor.isServer
    #  Meteor._sleepForMs(4000)

    throw new Meteor.Error(400, "please login") if !Meteor.userId()?

    if !answer.visitId? or answer.visitId.length is 0
      v = Visits.findOne
        userId: Meteor.userId()
      ,
        sort: {createdAt: -1, limit: 1}
      if v?
        answer.visitId = v._id
        console.log "found visit, that client didn't know about yet"
    if !answer.visitId? or answer.visitId.length is 0
      #answer.visitId = Meteor.call 'createVisit'
      #instead of calling createVisit we directly
      #create it here, so that it's synchronous
      #and this code works on client and server
      visit =
        userId: Meteor.userId()
        completed: false
      answer.visitId = Visits.insert visit

    visit = Visits.findOne
      userId: Meteor.userId()
      _id: answer.visitId
    throw new Meteor.Error(400, "visit can't be found.") unless visit?

    question = Questions.findOne
      _id:  answer.questionId
    throw new Meteor.Error(400, "question can't be found.") unless question?

    #check if not an answer has been created in the meantime
    #of calling this function (may occur multiple times at high rate)
    if not answer._id? and answer.visitId?
      a = Answers.findOne
        visitId: answer.visitId
        questionId: answer.questionId
      if a?
        console.log "found answer, that client didn't know about yet"
        answer._id = a._id

    if answer._id?
      a = Answers.findOne _.pick answer, 'visitId', 'questionId', '_id'
      throw new Meteor.Error(400, "answer to update can't be found.") unless answer?

      Answers.update answer._id,
        $set:
          value: answer.value
          consent: answer.consent
          importance: answer.importance
          status: answer.status
          radius: answer.radius
      answer._id
    else
      answer = _.pick answer, 'visitId', 'questionId', 'value', 'consent', 'importance', 'status', 'radius'
      _id = Answers.insert answer
      _id

  "deleteAllAnswers": ->
    throw new Meteor.Error(400, "you need to log in") unless Meteor.userId()?
    throw new Meteor.Error(403, "admin privileges required") unless Roles.userIsInRole(Meteor.userId(), 'admin')
    Answers.remove({})
