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

  #stub
  scoredDoc: ->
    sum = 0
    self = @validatedDoc()
    Questions.find().forEach (question) ->
      #only scale questions for now
      return if question.type isnt "scale"
      answer = Answers.findOne
        visitId: self._id
        questionId: question._id
      if answer?
        sum += answer.value
    score = 0.5
    if @numAnswered > 0
      score = sum/@numAnswered
    @score = score
    @progress = score*100
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


  "resetVisit": (visitId) ->
    throw new Meteor.Error(433, "you need to log to reset a visit") unless Meteor.userId()?
    check visitId, String

    visit = Visits.findOne
      _id: visitId
      userId: Meteor.userId()
    throw new Meteor.Error(403, "visit not found") unless visit?
    visit = visit.scoredDoc()

    if visit.isComplete #create a new one
      return Meteor.call "createVisit"
    else #delete it's answers
      Answers.remove
        visitId: visit._id
      return visit._id
