class @Answer
  constructor: (doc) ->
    _.extend this, doc

@Answers = new Meteor.Collection("answers",
  transform: (doc) ->
    new Answer(doc)
)

Answers.before.insert BeforeInsertTimestampHook
Answers.before.update BeforeUpdateTimestampHook

if Meteor.isServer #because of Meteor.call "createVisit"
  Meteor.methods
    "upsertAnswer": (answer) ->
      check(answer.questionId, String)

      throw new Meteor.Error(403, "missing user") if !Meteor.userId()?

      if !answer.visitId? or answer.visitId.length is 0
        v = Visits.findOne
          userId: Meteor.userId()
        ,
          sort: {createdAt: -1, limit: 1}
        if v?
          answer.visitId = v._id
          console.log "<<<<<<<<<<<>>>>>>>>>"
          console.log "found visit, that client didn't know about yet"
          console.log "<<<<<<<<<<<>>>>>>>>>"
      if !answer.visitId? or answer.visitId.length is 0
        answer.visitId = Meteor.call 'createVisit'

      visit = Visits.findOne
        userId: Meteor.userId()
        _id: answer.visitId
      throw new Meteor.Error(403, "visit can't be found.") unless visit?

      question = Questions.findOne
        _id:  answer.questionId
      throw new Meteor.Error(403, "question can't be found.") unless question?

      #check if not an answer has been created in the meantime
      #of calling this function (may occur multiple times at high rate)
      if not answer._id? and answer.visitId?
        a = Answers.findOne
          visitId: answer.visitId
          questionId: answer.questionId
        if a?
          console.log "<<<<<<<<<<<>>>>>>>>>"
          console.log "found answer, that client didn't know about yet"
          console.log "<<<<<<<<<<<>>>>>>>>>"
          answer._id = a._id

      if answer._id?
        a = Answers.findOne _.pick answer, 'visitId', 'questionId', '_id'
        throw new Meteor.Error(403, "answer to update can't be found.") unless answer?

        Answers.update answer._id,
          $set:
            value: answer.value
        answer._id
      else
        answer = _.pick answer, 'visitId', 'questionId', 'value'
        _id = Answers.insert answer
        _id
