class @Visit
  constructor: (doc) ->
    _.extend this, doc

  validatedDoc: ->
    valid = true
    self = @
    numAnswered = 0
    questions = Questions.find()
    .map (question) ->
      answer = Answers.findOne
        visitId: self._id
        questionId: question._id
      .fetch()
      valid = false if !answer?
      question.answered = answer?
      question.answer = answer
      question


@Visits = new Meteor.Collection("visits",
  transform: (doc) ->
    new Visit(doc)
)

Visits.before.insert BeforeInsertTimestampHook
Visits.before.update BeforeUpdateTimestampHook

Meteor.methods
  "createVisit": ->
    throw new Meteor.Error(433, "you need to log in to init a visit") unless Meteor.userId()?
    
    visit = 
      userId: Meteor.userId()
      completed: false

    _id = Visits.insert visit
    _id
