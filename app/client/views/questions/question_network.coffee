_numQuestions = new ReactiveVar(0)
_questionIndex = new ReactiveVar(0)
_showInfo = new ReactiveVar(false)
_visitId = new ReactiveVar()
_proPercent = new ReactiveVar()


radiusMax = 80
rScale = d3.scale.linear()
rScale.domain [0, 0.5]
rScale.range [20, radiusMax]

#TODO get from window height
linkDistanceMax = 800
linkDistanceScale = d3.scale.linear()
linkDistanceScale.domain [-0.5, 0.5]
linkDistanceScale.range [0, linkDistanceMax]

color = d3.scale.category20b()
colors = [
  '0CFF0C', 'BBFF0C', 'FFF113', 'FFBC13', 'FF8616', 'FF6311', 'FF190B', 'FF1361', 'EE0FFF', '9A15FF', '450FFF', '1437FF', '1B79FF', '13BBFF', '19EFFF', '19FF81', 'FF74E8', 'FFB669', '85FFC8', 'FF645B', 'B3FF62', 'FF3973'
]

_network = null
_beforeHoverIndex = null

Template.questionNetwork.created = ->
  self = @
  @autorun ->
    _numQuestions.set Questions.find().count()


Template.questionNetwork.rendered = ->
  network = new Network("#bubbles", radiusMax)
  _network = network

  #jump to question, when clicking on node
  network.onNodeClick (d) ->
    _questionIndex.set d.qIndex
    _beforeHoverIndex = null
  
  #jump to question, when hovering over node
  network.onNodeHover (d) ->
    if d?
      _beforeHoverIndex = _questionIndex.get() if not _beforeHoverIndex?
      _questionIndex.set d.qIndex
    else if _beforeHoverIndex?
      _questionIndex.set _beforeHoverIndex
      _beforeHoverIndex = null
    
  width = network.width()
  height = network.height()

  #get clusters from questions
  clusterIndices = {}
  i = 0
  Questions.find().forEach (q) ->
    clusterIndices[q.cluster] ?= []
    clusterIndices[q.cluster].push i
    i+=4
    return

  #draw cluster nodes
  numClusters = Object.keys(clusterIndices).length
  i = 0
  w = width-80
  Object.keys(clusterIndices).forEach (c) ->
    x = 40 + w/numClusters*i
    network.addNode
      id: c+'_max'
      fixed: true
      x: x
      y: 20
      radius: 0
    network.addNode
      id: c+'_min'
      fixed: true
      x: x
      y: height-20
      radius: 0
    i+=1

  @autorun ->
    selectedVisitId = Session.get 'selectedVisitId'
    if selectedVisitId?
      v = Visits.findOne selectedVisitId
    else
      v = Visits.findOne {},
        sort: {createdAt: -1, limit: 1}

    return if !v?

    _visitId.set v._id

    Tracker.nonreactive ->
      network.removeAllLinks()
      network.removeAllNodes()
      Answers.find
        visitId: v._id
      .forEach (answer) ->
        question = Questions.findOne answer.questionId
        answerAdded(answer, question)
    #.observe
    #  added: (answer) ->
    #    question = Questions.findOne answer.questionId
    #    answerAdded(answer, question)

    #  changed: (answer) ->
    #    question = Questions.findOne answer.questionId
    #    answerChanged(answer, question)

    #  removed: (answer) ->
    #    question = Questions.findOne answer.questionId
    #    if question?
    #      network.removeNode question._id
    #    else
    #      network.removeAllLinks
    #      network.removeAllNodes

  @autorun ->
    total = 0
    pro = 0
    visitId = _visitId.get()
    Answers.find
      visitId: visitId
    .forEach (answer) ->
      question = Questions.findOne answer.questionId
      value = answer.value
      radius = rScale( Math.abs(value) )
      if question.isOneSided and value is 0
        radius = 0

      a = 2*Math.PI*Math.pow(radius, 2)
      total += a
      if value > 0
        pro += a
      return

    proPercent = 100*pro/total
    proPercent = 0 if total is 0
    proPercent = Math.round(proPercent)
    _proPercent.set proPercent


Template.questionNetwork.helpers
  visit: ->
    v = Visits.findOne _visitId.get()
    return v.scoredDoc() if v?
    null

  hasAnswers: ->
    @visit? and @visit.numAnswered > 0

  question: ->
    Questions.findOne
      index: _questionIndex.get()

  answerForQuestion: (visitId, questionId) ->
    return null if !visitId?
    Answers.findOne
      visitId: visitId
      questionId: questionId

  proPercent: ->
    _proPercent.get()

Template.questionNetwork.events
  'click #back': (evt, tmpl) ->
    _showInfo.set false
    qi = _questionIndex.get()-1
    if qi < 0
      _questionIndex.set _numQuestions.get()-1
    else
      _questionIndex.set qi

  'click #next': (evt, tmpl) ->
    _showInfo.set false
    qi = _questionIndex.get()+1
    if qi is _numQuestions.get()
      _questionIndex.set 0
    else
      _questionIndex.set qi

  'click .showInfo': (evt) ->
    evt.preventDefault()
    _showInfo.set true

  'click .hideInfo': (evt) ->
    evt.preventDefault()
    _showInfo.set false


Template.questionTemplate.helpers
  showInfo: ->
    _showInfo.get()

  showSlider: ->
    @answer? and @answer.consent? and
    (not @question.isOneSided or
    @question.isOneSided and 
    (not @question.isOnlyNegative and @answer.consent is 0.5 or
    @question.isOnlyNegative and @answer.consent is -0.5))

  activeCSS: (bool) ->
    if @answer?
      if bool and @answer.consent is @question.max
        return "active"
      if !bool and @answer.consent is @question.min
        return "active"
    return ""

Template.questionTemplate.events
  'click button': (evt, tmpl, val) ->
    evt.target.blur()
    if tmpl.$(evt.target).hasClass("yes")
      consent = @question.max
    else
      consent = @question.min
    updateAnswer(consent, null, @)
    return

  'slide': (evt, tmpl, val) ->
    importance = parseFloat val
    updateAnswer(null, importance, @)
    return

Template.slider.rendered = ->
  tmpl = @
  prevQuestionId = null
  prevConsent = null
  @autorun ->
    data = Template.currentData()
    if !data.answer? or !data.answer.consent? 
      return
    answer = data.answer
    question = data.question
    if question._id is prevQuestionId and answer.consent is prevConsent
      return #only answer changed
    prevQuestionId = question._id
    prevConsent = answer.consent
    start = 0.5
    if answer? and answer.importance?
      start = answer.importance 
    try
      document.getElementById('nouislider').destroy()
    catch e
      #console.log e
    tmpl.$('.nouislider').noUiSlider(
      start: start
      #step: question.step
      range:
        min: 0
        max: 1
    )
    return
  return


_upsertTimeout = null
updateAnswer = (consent, importance, data) ->
  a = data.answer || {}
  newConsent = consent
  newConsent ?= a.consent
  #consent should be provided first
  debugger if not newConsent?
  newImportance = importance
  newImportance ?= a.importance
  newImportance ?= 0.5
  newValue = newConsent*newImportance
  a = _.extend a,
    visitId: data.visit._id if data.visit?
    questionId: data.question._id
    consent: newConsent
    importance: newImportance
    value: newValue
  if not a._id? and (not a.added? or not a.added)
    console.log "added"
    a.added = true
    data.answer = a #chache in template data
    answerAdded(a, data.question)
  else
    console.log "changed"
    answerChanged(a, data.question)
  Meteor.clearTimeout _upsertTimeout if _upsertTimeout?
  _upsertTimeout = Meteor.setTimeout ->
    ensureUser().then ->
      console.log "upsertAnswer"
      Meteor.call "upsertAnswer", a, (error) ->
        throwError error if error?
  , 500


answerAdded = (answer, question) ->
  value = answer.value
  radius = rScale( Math.abs(value) )
  if value is 0
    radius = 0
  node =
    id: question._id
    qIndex: question.index
    answerValue: value
    x: _network.width() 
    y: _network.height()/2
    radius: radius
    #color: d3.rgb(color(clusterIndices[question.cluster])).brighter(value)
    color: "#"+colors[question.index]
  _network.addNode node

  ldMin = linkDistanceScale(value)
  _network.addLink
    sourceId: node.id
    targetId: question.cluster+'_min'
    linkDistance: ldMin
  _network.addLink
    sourceId: node.id
    targetId: question.cluster+'_max'
    linkDistance: linkDistanceMax-ldMin

answerChanged = (answer, question) ->
  value = answer.value
  radius = rScale( Math.abs(value) )
  if value is 0
    radius = 0
  _network.changeNode
    id: question._id
    answerValue: value
    radius: radius
    #color: d3.rgb(color(clusterIndices[question.cluster])).brighter(value)
    color: "#"+colors[question.index]

  ldMin = linkDistanceScale(value)
  _network.changeLink
    sourceId: question._id
    targetId: question.cluster+'_min'
    linkDistance: ldMin
  _network.changeLink
    sourceId: question._id
    targetId: question.cluster+'_max'
    linkDistance: linkDistanceMax-ldMin
  return
