class @Visit
  constructor: (doc) ->
    _.extend this, doc

  validatedDoc: ->
    hasAnswers = false
    isComplete = true
    numAnswered = 0
    numQuestions = 0
    self = @
    questions = Questions.find()
    .map (question) ->
      answer = Answers.findOne
        visitId: self._id
        questionId: question._id
      numQuestions += 1
      if answer?
        hasAnswers = true
        numAnswered += 1
        question.answered = true
        question.answer = answer 
      else
        isComplete = false
        question.answered = false
      question
    @isComplete = isComplete
    @hasAnswers = hasAnswers
    @numQuestions = numQuestions
    @numAnswered = numAnswered
    @questions = questions
    @


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
