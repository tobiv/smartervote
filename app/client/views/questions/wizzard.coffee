_numQuestions = new ReactiveVar(0)
_numPages = new ReactiveVar(0)
_questionIdsForPage = new ReactiveVar({})
_pageIndex = new ReactiveVar(0)
_numFormsToSubmit = 0

nextPage = ->
  if _pageIndex.get() is _numPages.get()-1
    #TODO goto results
    Router.go 'home'
  else
    _pageIndex.set _pageIndex.get()+1

previousPage = ->
  index = _pageIndex.get()
  index -= 1 if index > 0
  _pageIndex.set index


_gotoNextPage = null
submitAllForms = (gotoNextPage) ->
  _gotoNextPage = gotoNextPage
  numFormsToSubmit = 0
  $("form").each () ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('question') > -1
      numFormsToSubmit += 1
  _numFormsToSubmit = numFormsToSubmit
  #console.log "numFormsToSubmit "+numFormsToSubmit
  $("form").each () ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('question') > -1
      e.submit()

formSubmitted = ->
  if (_numFormsToSubmit -= 1) <= 0
    if _gotoNextPage is true
      nextPage()
    if _gotoNextPage is false
      previousPage()


autoformHooks =
  onSubmit: (insertDoc, updateDoc, currentDoc) ->
    self = @
    ensureUser().then ->
      upsertAnswer.call(self, insertDoc, updateDoc, currentDoc)
    ,
      (error) ->
        console.log "ensureUser rejected"
        throwError error if error?
    false


#this: onSubmit
upsertAnswer = (insertDoc, updateDoc, currentDoc) ->
  insertDoc.visitId = currentDoc.visitId  if currentDoc.visitId?
  insertDoc.questionId = currentDoc.questionId
  insertDoc._id = currentDoc._id if currentDoc._id?
  #console.log "submit questionAutoform"
  #console.log insertDoc
  if insertDoc.value? and (!currentDoc.value? or (currentDoc.value? and currentDoc.value isnt insertDoc.value))
    Meteor.call "upsertAnswer", insertDoc, (error) ->
      throwError error if error?
  formSubmitted()
  @done()


Template.wizzard.created = ->
  self = @
  @autorun ->
    count = 0
    page = 0
    questionIdsForPage = {}
    didBreakPage = false
    autoformIds = []
    Questions.find {},
      sort: {index: 1}
    .forEach (q) ->
      autoformIds.push q._id
      count += 1
      if questionIdsForPage[page]?
        questionIdsForPage[page].push q._id
      else
        questionIdsForPage[page] = [q._id]
      didBreakPage = false
      if q.break
        page += 1
        didBreakPage = true

    page -= 1 if didBreakPage
    _questionIdsForPage.set questionIdsForPage
    _numQuestions.set count
    _numPages.set page+1
    _pageIndex.set 0
    AutoForm.addHooks(autoformIds, autoformHooks, true)

Template.wizzard.helpers
  templateGestures:
    'swipeleft div': (evt, templateInstance) ->
      nextQuestion()

    'swiperight div': (evt, templateInstance) ->
      previousQuestion()

  visit: ->
    selectedVisitId = Session.get 'selectedVisitId'
    if selectedVisitId?
      v = Visits.findOne selectedVisitId
    else
      v = Visits.findOne {},
        sort: {createdAt: -1, limit: 1}
    #console.log "visitId: #{v._id}" if v?
    return v.scoredDoc() if v?
    null

  hasAnswers: ->
    @visit? and @visit.numAnswered > 0

  questionsForPage: ->
    questionIdsForPage = _questionIdsForPage.get()[_pageIndex.get()]
    Questions.find
      _id: {$in: questionIdsForPage}
    ,
      sort: {index: 1}

  answerForQuestion: (visitId, questionId) ->
    return null if !visitId?
    Answers.findOne
      visitId: visitId
      questionId: questionId

  answerFormSchema: ->
    schema =
      _id:
        type: String
        optional: true
      visitId:
        type: String
        optional: true
      questionId:
        type: String
        optional: true
      value: @question.getSchemaDict()
    new SimpleSchema(schema)

  doc: ->
    @answer or
      questionId: @question._id
      visitId: @visit._id if @visit?

  isOnFirstPage: ->
    _pageIndex.get() is 0
  isOnLastPage: ->
    _pageIndex.get() is _numPages.get()-1

  pages: ->
    questionIds = Questions.find().map (question) ->
      question._id
    answers = {}
    if @visit?
      Answers.find
        visitId: @visit._id
        questionId: {$in: questionIds}
      .forEach (answer) ->
        answers[answer.questionId] = answer
    #console.log answers
    activeIndex = _pageIndex.get()
    questionIdsForPage = _questionIdsForPage.get()
    pages = []
    for i in [0.._numPages.get()-1]
      css = ""
      allQuestionsAnsweredInPage = true
      Questions.find
        _id: {$in: questionIdsForPage[i]}
      .forEach (question) ->
        if !answers[question._id]?
          allQuestionsAnsweredInPage = false
      if allQuestionsAnsweredInPage
        css = "answered"
      if i is activeIndex
        css += " active"
      pages[i] =
        index: i+1
        css: css
    pages


Template.wizzard.events
  "click #next": (evt, tmpl) ->
    submitAllForms(true)
    false

  "click #back": (evt, tmpl) ->
    submitAllForms(false)
    false

  "click .jumpToPage": (evt) ->
    submitAllForms(null)
    _pageIndex.set @index-1
    false

  "click #reset": (evt, tmpl) ->
    Meteor.call "resetVisit", @visit._id, (error, id) ->
      throwError error if error?
      if Session.get('selectedVisitId')?
        Session.set 'selectedVisitId', id
    false
