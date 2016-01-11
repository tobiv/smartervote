_numQuestions = new ReactiveVar(0)
_questionIndex = new ReactiveVar(0)
_showInfo = new ReactiveVar(false)
_visitId = new ReactiveVar()
_proPercent = new ReactiveVar()
Template.questionNetwork.created = ->
  self = @
  @autorun ->
    _numQuestions.set Questions.find().count()


Template.questionNetwork.rendered = ->
  radiusMax = 80
  network = new Network("#bubbles", radiusMax)

  #jump to question, when clicking on node
  network.onNodeClick (d) ->
    _questionIndex.set d.qIndex
    
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
  @autorun ->
    selectedVisitId = Session.get 'selectedVisitId'
    if selectedVisitId?
      v = Visits.findOne selectedVisitId
    else
      v = Visits.findOne {},
        sort: {createdAt: -1, limit: 1}

    return if !v?

    _visitId.set v._id
    Answers.find
      visitId: v._id
    .observe
      added: (answer) ->
        question = Questions.findOne answer.questionId
        value = answer.value
        if question.type is 'boolean'
          value = -0.5 if !answer.value
          value = 0.5 if answer.value
        radius = rScale( Math.abs(value) )
        if question.isOneSided and value is 0
          radius = 0
        node =
          id: question._id
          qIndex: question.index
          answerValue: value
          x: width
          y: height/2
          radius: radius
          #color: d3.rgb(color(clusterIndices[question.cluster])).brighter(value)
          color: "#"+colors[question.index]
        network.addNode node

        ldMin = linkDistanceScale(value)
        network.addLink
          sourceId: node.id
          targetId: question.cluster+'_min'
          linkDistance: ldMin
        network.addLink
          sourceId: node.id
          targetId: question.cluster+'_max'
          linkDistance: linkDistanceMax-ldMin

      changed: (answer) ->
        question = Questions.findOne answer.questionId
        value = answer.value
        if question.type is 'boolean'
          value = -0.5 if !answer.value
          value = 0.5 if answer.value
        radius = rScale( Math.abs(value) )
        if question.isOneSided and value is 0
          radius = 0
        network.changeNode
          id: question._id
          answerValue: value
          radius: radius
          #color: d3.rgb(color(clusterIndices[question.cluster])).brighter(value)
          color: "#"+colors[question.index]

        ldMin = linkDistanceScale(value)
        network.changeLink
          sourceId: question._id
          targetId: question.cluster+'_min'
          linkDistance: ldMin
        network.changeLink
          sourceId: question._id
          targetId: question.cluster+'_max'
          linkDistance: linkDistanceMax-ldMin

      removed: (answer) ->
        question = Questions.findOne answer.questionId
        if question?
          network.removeNode question._id
        else
          network.removeAllLinks
          network.removeAllNodes

  @autorun ->
    total = 0
    pro = 0
    visitId = _visitId.get()
    Answers.find
      visitId: visitId
    .forEach (answer) ->
      question = Questions.findOne answer.questionId
      value = answer.value
      if question.type is 'boolean'
        value = -0.5 if !answer.value
        value = 0.5 if answer.value
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


Template.scaleQuestion.rendered = ->
  tmpl = @
  prevQuestionId = null
  @autorun ->
    data = Template.currentData()
    question = data.question
    if question._id is prevQuestionId
      return #only answer changed
    prevQuestionId = question._id
    answer = data.answer
    if answer? and answer.value?
      start = answer.value 
    else
      start = question.start
    try
      document.getElementById('nouislider').destroy()
    catch e
      #console.log e
    tmpl.$('.nouislider').noUiSlider(
      start: start
      #step: question.step
      range:
        min: question.min
        max: question.max
    )
    return
  return

Template.scaleQuestion.helpers
  showInfo: ->
    _showInfo.get()

_pause = false
Template.scaleQuestion.events
  'slide': (evt, tmpl, val) ->
    return if _pause
    _pause = true
    a = @answer || {}
    a.visitId = @visit._id if @visit?
    a.questionId = @question._id
    a.value = parseFloat(val)
    ensureUser().then ->
      Meteor.call "upsertAnswer", a, (error) ->
        throwError error if error?
        _pause = false


Template.booleanQuestion.helpers
	activeCSS: (bool) ->
		"active" if @answer? and bool is @answer.value

	showInfo: ->
		_showInfo.get()

Template.booleanQuestion.events
  'click button': (evt, tmpl, val) ->
    event.target.blur()
    return if _pause
    _pause = true
    a = @answer || {}
    a.visitId = @visit._id if @visit?
    a.questionId = @question._id
    a.value = tmpl.$(evt.target).hasClass("yes")
    ensureUser().then ->
      Meteor.call "upsertAnswer", a, (error) ->
        throwError error if error?
        _pause = false
