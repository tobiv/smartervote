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
        answer.visitId = v._id if v?
      if !answer.visitId? or answer.visitId.length is 0
        answer.visitId = Meteor.call 'createVisit'

      visit = Visits.findOne
        userId: Meteor.userId()
        _id: answer.visitId
      throw new Meteor.Error(403, "visit can't be found.") unless visit?

      question = Questions.findOne
        _id:  answer.questionId
      throw new Meteor.Error(403, "question can't be found.") unless question?

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
