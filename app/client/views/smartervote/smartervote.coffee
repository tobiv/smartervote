radiusMax = 80
rScale = d3.scale.linear()
rScale.domain [0, 0.5]
rScale.range [20, radiusMax]

linkDistanceMax = 800
linkDistanceScale = d3.scale.linear()
linkDistanceScale.domain [-0.5, 0.5]
linkDistanceScale.range [0, linkDistanceMax]

_colors = [
  [ '00f384', '2ff56b' ]
  [ '34f569', '6af84d' ]
  [ '6ff84b', '9bfa34' ]
  [ 'a0fb31', 'c1fc20' ]
  [ 'c6fc1d', 'dffd11' ]
  [ 'e1fe10', 'f3fe06' ]
  [ 'feff01', 'fff708' ]
  [ 'fff30c', 'ffd827' ]
  [ 'ffd52a', 'ffb748' ]
  [ 'ffb44b', 'ff9669' ]
  [ 'ff936c', 'ff748b' ]
  [ 'ff718e', 'ff52ad' ]
  [ 'ff4db2', 'ff2fd0' ]
  [ 'ff2ad5', 'ff0bf4' ]
  [ 'ff08f7', 'e725ff' ]
  [ 'e32aff', 'c558ff' ]
  [ 'c25cff', 'a784ff' ]
  [ 'a489ff', '8dabff' ]
  [ '8bafff', '77cdff' ]
  [ '76cfff', '66e7ff' ]
  [ '64eaff', '5af9ff' ]
  [ '59fbff', '56ffff' ]
]

_clusters = []
_topics = []

_network = null
_beforeHoverIndex = null
_beforeHoverShowEvaluation = null

_chain = null
_pitcher = null
_field = null

_visitId = null
_answers = {}
_answerSaver = null
_proPercent = ReactiveVar(0)
_clustersAdded = false

_numQuestions = 0

_questionIndex = new ReactiveVar(-1)
_showInfo = new ReactiveVar(false)
_previousSelectedId = null
_activeAnswerTrigger = new ReactiveVar(false)

_questionLabelLengthMax = 5

_breakpointX = 768


getBubblesWidth = ->
  wWidth = $(window).width()
  w = $('#content').offset().left
  if wWidth <= _breakpointX
    w = wWidth
  w

_resizeTimeout = null
@resize = ->
  Meteor.clearTimeout(_resizeTimeout) if _resizeTimeout?
  _resizeTimeout = Meteor.setTimeout(doResize, 100)
  return

doResize = ->
  return if !_network?
  #console.log "doResize"
  wWidth = $(window).width()
  wHeight = $(window).height()

  _network.resize()

  upsertClusters()

  #move pitcher
  footer = $('.footer')
  if footer? and footer.length > 0
    _network.changeNode
      id: 'pitcher'
      px: footer.offset().left + footer.width()/2
      py: footer.offset().top-50

  #move chain
  bc = $('#bubbles-container')
  bcw = bc.width()
  bch = bc.height()
  _network.changeNode
    id: 'chain_top'
    px: bcw
    py: 0
  _network.changeNode
    id: 'chain_bottom'
    px: bcw
    py: bch

  #refresh xMax of field
  _field.setXMax getBubblesWidth()

  # recalculate content padding
  footerHeight = @$('.footer').outerHeight()
  @$('#question').css( 'padding-bottom', footerHeight )


upsertClusters = ->
  numClusters = _clusters.length
  width = getBubblesWidth()
  height = $(window).height()
  i = 0
  _clusters.forEach (c) ->
    x = 40+Math.round(width/numClusters*i)
    i += 1
    if !_clustersAdded
      _network.addNode
        id: c+'_max'
        fixed: true
        x: x
        y: 0
        radius: 0
        #fillColor: '#000'
      _network.addNode
        id: c+'_min'
        fixed: true
        x: x
        y: height
        radius: 0
        #fillColor: '#000'
    else
      _network.changeNode
        id: c+'_max'
        px: x
      _network.changeNode
        id: c+'_min'
        px: x
        py: height
  _clustersAdded = true

Template.smartervote.destroyed = ->
  $(window).off("resize", resize)
  _clusters = []
  _topics = []
  _network = null
  _beforeHoverIndex = null
  _beforeHoverShowEvaluation = null
  _chain = null
  _pitcher = null
  _field = null
  _visitId = null
  _answers = {}
  _answerSaver = null
  _proPercent = ReactiveVar(0)
  _clustersAdded = false
  _numQuestions = 0
  _previousSelectedId = null

Template.smartervote.rendered = ->
  Session.set 'showEvaluation', false
  #initialize network
  _network = new Network("#bubbles-container", radiusMax)

  for color, i in _colors
    _network.appendGradient 'color_'+i, '#'+color[0], '#'+color[1]

  #jump to question, when clicking on node
  _network.onNodeClick (d) ->
    gotoQuestionIndex d.qIndex
    _beforeHoverIndex = null
    _beforeHoverShowEvaluation = null
    Session.set 'showEvaluation', false
    $('#content').fadeIn(200)
    $('#bubbles-container').removeClass('dim')

  #jump to question, when hovering over node
  _network.onNodeHover (d) ->
    if d?
      _beforeHoverIndex = _questionIndex.get() if not _beforeHoverIndex?
      _questionIndex.set d.qIndex
      _beforeHoverShowEvaluation = Session.get('showEvaluation') if not _beforeHoverShowEvaluation?
      Session.set 'showEvaluation', false
    else
      if _beforeHoverIndex?
        _questionIndex.set _beforeHoverIndex
        _beforeHoverIndex = null
      if _beforeHoverShowEvaluation?
        Session.set 'showEvaluation', _beforeHoverShowEvaluation
        _beforeHoverShowEvaluation = null

  _numQuestions = Questions.find().count()

  #get clusters and topics from questions and draw them
  clusters = []
  topics = []
  i = 0
  qs = Questions.find({}, {sort: {index: 1}}).forEach (q) ->
    if clusters.indexOf(q.cluster) is -1
      clusters.push q.cluster
    if topics.indexOf(q.topic) is -1
      topics.push q.topic
    return
  _clusters = clusters
  _topics = topics

  _answerSaver = new AnswerSaver()

  upsertClusters()

  #load initially and on visit change
  @autorun (computation)->
    #computation.onInvalidate ->
    #  console.trace()
    selectedVisitId = Session.get 'selectedVisitId'
    if selectedVisitId?
      visit = Visits.findOne selectedVisitId
    else
      visit = Visits.findOne {},
        sort: {createdAt: -1, limit: 1}

    if visit?
      if _visitId? and visit._id isnt _visitId #we had a different visit before
        window.location.reload(false)
        return
      _visitId = visit._id
      Session.set 'visitId', _visitId


  #init network elements
  _chain = new Chain(_network)
  _pitcher = new Pitcher(_network)
  _field = new Field(_network)

  #subscribe to resize
  $(window).resize(resize)

  #TODO make this work to remove reload
  #if _answers.length > 0
  #  #remove all answers
  #  console.log "remove all answers"
  #  while ((answer = _answers.pop())?)
  #    _network.removeNode answer.question._id
  #  _answers.length = 0
  #  return

  Tracker.nonreactive ->
    #draw all available answers and remaining questions
    Questions.find({}, {sort: {index: 1}}).forEach (question) ->
      answer = null
      if _visitId?
        answer = Answers.findOne
          visitId: _visitId
          questionId: question._id
      if answer?
        answer.question = question
        if answer.status is 'valid' or answer.status is 'dead'
          answer.position = 'field'
          _answers[question._id] = answer
          _field.buildAndCatch answer
        else
          answer.position = 'chain'
          _answers[question._id] = answer
          _chain.buildAndCatch answer
      else
        #init answer
        answer =
          question: question
          questionId: question._id #needed on server
          position: 'chain'
          status: 'new'
          radius: rScale( Math.abs(0.25) )
        _answers[question._id] = answer
        _chain.buildAndCatch answer
    #init proPercent
    _proPercent.set Answer.getProPercent( Object.keys(_answers).map (key) ->
      _answers[key]
    )
    goNext()
    Meteor.setTimeout ->
      resize()
      if _questionIndex.get() is -1
        goNext()
    , 500

  @autorun ->
    #maintain selected node
    if _previousSelectedId?
      _network.changeNode 
        id: _previousSelectedId
        removeClasses: true
      _previousSelectedId = null
    index = _questionIndex.get()
    question = Questions.findOne index: index
    _network.changeNode 
      id: question._id
      classes: "selected"
    _previousSelectedId = question._id



Template.smartervote.helpers
  showEvaluation: ->
    Session.get 'showEvaluation'

  proPercent: ->
    _proPercent.get()
    
  proPercentGauge: ->
    _proPercent.get() * 0.88
    

Template.smartervote.events
  'click .site-menu-toggle': () ->
    $('#overlay-menu').fadeIn(200)
    
  'click #mobile-content-toggle': () ->
    $('#content').fadeToggle(200)
    $('#bubbles-container').toggleClass('dim')


Template.question.rendered = ->
  # @$("#question").mCustomScrollbar({ theme: 'minimal-dark', scrollButtons: { enable: false } })

  footerHeight = $('.footer').outerHeight()
  $('#question').css( 'padding-bottom', footerHeight )

Template.question.helpers
  question: ->
    Questions.findOne
      index: _questionIndex.get()

  maxLabel: ->
    if @question?
      if @question.maxLabel.indexOf(',') is -1 and
      @question.maxLabel.length > _questionLabelLengthMax
        return ''
      @question.maxLabel.split(',')[0]

  maxLabelAffix: ->
    if @question?
      if @question.maxLabel.indexOf(',') is -1 and
      @question.maxLabel.length > _questionLabelLengthMax
        return @question.maxLabel
      @question.maxLabel.split(',')[1]

  minLabel: ->
    if @question?
      if @question.minLabel.indexOf(',') is -1 and
      @question.minLabel.length > _questionLabelLengthMax
        return ''
      @question.minLabel.split(',')[0]

  minLabelAffix: ->
    if @question?
      if @question.minLabel.indexOf(',') is -1 and
      @question.minLabel.length > _questionLabelLengthMax
        return @question.minLabel
      @question.minLabel.split(',')[1]

  index: ->
    @question.index+1 if @question?

  showInfo: ->
    _showInfo.get()

  favoriteActive: (bool) ->
    _activeAnswerTrigger.get()
    if @question?
      answer = _answers[@question._id]
      if answer? and answer.isFavorite
        return "active"
    return ""

  answerButtonActive: (bool) ->
    _activeAnswerTrigger.get()
    if @question?
      answer = _answers[@question._id]
      if answer?
        if bool and answer.consent is @question.max
          return "active"
        if !bool and answer.consent is @question.min
          return "active"
    return ""

  

Template.question.events
  'click .max': (evt, tmpl) ->
    evt.target.blur()
    updateAnswer(@question.max, null, @question)
    _activeAnswerTrigger.set(!_activeAnswerTrigger.get())
    return

  'click .min': (evt, tmpl) ->
    evt.target.blur()
    updateAnswer(@question.min, null, @question)
    _activeAnswerTrigger.set(!_activeAnswerTrigger.get())
    return

  'slide': (evt, tmpl, val) ->
    $('#content, #bubbles-container').addClass('dim')
    importance = parseFloat val
    updateAnswer(null, importance, @question)
    _activeAnswerTrigger.set(!_activeAnswerTrigger.get())
    return
    
  'mouseup': () ->
    $('#content, #bubbles-container').removeClass('dim')

  'touchend': () ->
    $('#content, #bubbles-container').removeClass('dim')
    
  'click #next': (evt, tmpl) ->
    _showInfo.set false
    next(@question)

  'click #back': (evt, tmpl) ->
    _showInfo.set false
    qi = Session_.pop 'questionIndices'
    if qi is _questionIndex.get()
      qi = Session_.pop 'questionIndices'
    if !qi?
      qi = _questionIndex.get()-1
    #roundrobin
    if qi < 0
      qi = _numQuestions-1
    gotoQuestionIndex qi

  'click #toggle-favorite': (evt) ->
    answer = _answers[@question._id]
    if answer.isFavorite?
      answer.isFavorite = !answer.isFavorite
    else
      answer.isFavorite = true
    _activeAnswerTrigger.set(!_activeAnswerTrigger.get())
    _network.changeNode
      id: @question._id
      isFavorite: answer.isFavorite
      isDead: answer.status isnt 'valid'
    _answerSaver.upsertAnswer @question._id

  'click .showInfo': (evt) ->
    evt.preventDefault()
    _showInfo.set true
    #http://stackoverflow.com/questions/3485365/how-can-i-force-webkit-to-redraw-repaint-to-propagate-style-changes
    #http://stackoverflow.com/questions/8840580/force-dom-redraw-refresh-on-chrome-mac
    $('#header').hide().show(0)
    document.getElementById('header').style.display = 'none'
    document.getElementById('header').offsetHeight
    document.getElementById('header').style.display = ''

  'click .hideInfo a': (evt) ->
    evt.preventDefault()
    _showInfo.set false
    $('#header').hide().show(0)

  "click #reset": (evt, tmpl) ->
    Meteor.call "resetVisit", _visitId, (error, id) ->
      throwError error if error?
      if Session.get('selectedVisitId')?
        Session.set 'selectedVisitId', id

  'click #gotoEvaluation': (evt) ->
    evt.preventDefault()
    Session.set 'showEvaluation', true


Template.slider.rendered = ->
  tmpl = @
  prevQuestionId = null
  prevConsent = null
  @autorun ->
    question = Template.currentData().question
    return if !question?
    answer = _answers[question._id]
    if answer? and question._id is prevQuestionId and answer.consent is prevConsent
      return #only answer changed
    prevQuestionId = question._id
    prevConsent = answer.consent if answer?
    start = 0.5
    if answer? and answer.importance?
      start = answer.importance
    try
      document.getElementById('nouislider').destroy()
    catch e
      #console.log e
    tmpl.$('.nouislider').noUiSlider(
      start: start
      range:
        min: 0
        max: 1
    )
    return
  return

gotoQuestionIndex = (newIndex) ->
  #clear pitcher
  answer = _pitcher.getAnswer()
  if answer? and answer.position is 'pitcher'
    updateAnswer(null, null, answer.question)
    _chain.catch answer
    _pitcher.free()
    answer.position = "chain"
    _answers[answer.question._id] = answer
  #edit newIndex
  question = Questions.findOne
    index: newIndex
  answer = _answers[question._id]
  if answer.position is 'chain'
    _chain.free answer
    _pitcher.catch answer
    answer.position = "pitcher"
    _answers[question._id] = answer
  _questionIndex.set newIndex
  Session_.push 'questionIndices', newIndex
  return


next = (question) ->
  answer = _answers[question._id]
  debugger if !answer?
  updateAnswer(null, null, question)
  if answer.position is 'pitcher'
    _chain.catch answer
    _pitcher.free()
    answer.position = "chain"
    _answers[question._id] = answer
  goNext()

goNext = ->
  nextItem = _chain.shift()
  if nextItem?
    question = nextItem.question
    answer = _answers[question._id]
    answer.position = "pitcher"
    _answers[question._id] = answer
    _pitcher.catch answer
    _questionIndex.set question.index
    Session_.push 'questionIndices', question.index
  else
    qi = _questionIndex.get()+1
    if qi is _numQuestions
      qi = 0
    _questionIndex.set qi
    Session_.push 'questionIndices', qi

updateAnswer = (consent, importance, question) ->
  answer = _answers[question._id]

  newConsent = consent
  newConsent ?= answer.consent
  newConsent ?= null
  newImportance = importance
  newImportance ?= answer.importance
  newImportance ?= null

  if newConsent is null and newImportance is null
    newValue = 0.25
  else if newConsent is null and newImportance isnt null
    newValue = newImportance * 0.5
  else if newConsent isnt null and newImportance is null
    newImportance = 0.5
  if newConsent isnt null and newImportance isnt null
    newValue = newConsent*newImportance

  newRadius = rScale( Math.abs(newValue) )

  newStatus = "valid"
  if newImportance is 0 or question.isOneSided and newConsent is 0
    newStatus = 'dead'
  else if newConsent is null
    newStatus = 'skipped'

  newAnswer = _.extend answer,
    consent: newConsent
    importance: newImportance
    value: newValue
    radius: newRadius
    status: newStatus

  if importance isnt null and consent is null #updated importance
    if answer.position is 'pitcher'
      _pitcher.update newAnswer
    else if answer.position is 'field'
      if newAnswer.status is 'valid'
        _field.update newAnswer
      else
        debugger if newAnswer.status is 'skipped'
        #new: stay on field instead of back to chain
        _field.update newAnswer
    else if answer.position is 'chain'
      if newAnswer.status is 'valid'
        #console.log "back to field"
        newAnswer.position = "field"
        _field.catch newAnswer
        _chain.free newAnswer

  if consent isnt null and importance is null #updated consent
    if answer.position is 'pitcher'
      #new to field anyway instead of from pitcher to field or back to chain
      newAnswer.position = "field"
      _field.catch newAnswer
      _pitcher.free()
    else if answer.position is 'field'
      if newAnswer.status is 'valid'
        _field.update newAnswer
      else
        debugger if newAnswer.status is 'skipped'
        #new: stay on field instead of back to chain
        _field.update newAnswer
    else if answer.position is 'chain'
      #new to field anyway instead of back to field if valid
      newAnswer.position = "field"
      _field.catch newAnswer
      _chain.free newAnswer

  if consent is -1 and importance is -1#next / back
    if answer.position is 'pitcher'
      #console.log "back to chain"
      newAnswer.position = "chain"
      _chain.catch newAnswer
      _pitcher.free()

  _answers[question._id] = newAnswer

  #update proPercent
  _proPercent.set Answer.getProPercent( Object.keys(_answers).map (key) ->
    _answers[key]
  )

  if newAnswer.status isnt 'skipped'
    _answerSaver.upsertAnswer question._id
  return

class AnswerSaver
  call = Promise.promisify(Meteor.call, Meteor)
  constructor: ->
    #init instance vars
    @ids = []
    @saveTimeout = null
    @saving = false
    @saveAgain = false

  upsertAnswer: (id) ->
    @ids.unshift id
    @ids = _.unique @ids
    @saveAll()

  saveAll: () ->
    #console.log "saveAll"
    if @saving
      @saveAgain = true
      return
    Meteor.clearTimeout(@saveTimeout) if @saveTimeout?
    self = @
    @saveTimeout = Meteor.setTimeout ->
      self.doSaveAll()
    , 1000

  doSaveAll: () ->
    #console.log "doSaveAll--"
    idsToPush = _.clone @ids
    @ids.length = 0
    @saving = true
    self = @
    Promise.each(idsToPush, (id)->
      answer = _answers[id]
      answer.visitId = _visitId if _visitId?
      #console.log "saving #{answer.question._id}"
      call('upsertAnswer', answer).then( (answerId)->
        #console.log "#{answerId} saved"
        #console.log answer
        _answers[answer.question._id]._id = answerId
      )
    ).catch( (e) ->
      #console.log "exception during doSaveAll"
      console.log e
      Promise.delay(4000).then ->
        idsToPush.forEach (id) ->
          _answerSaver.upsertAnswer id
    ).finally ->
      #console.log "all answers saved"
      self.saving = false
      if self.saveAgain
        self.saveAgain = false
        _answerSaver.saveAll()
    return


class Pitcher
  constructor: (ourNetwork) ->
    @network = ourNetwork
    #init instance vars
    @holdingAnswer = null
    #answering pitcher
    #gets repositioned by resize()
    @network.addNode
      id: 'pitcher'
      fixed: true
      x: 800
      y: 400
      radius: 0
      #fillColor: '#000'

  catch: (answer) ->
    debugger if @holdingAnswer?
    @holdingAnswer = answer
    @update answer
    @network.addLink
      sourceId: 'pitcher'
      targetId: answer.question._id
      linkDistance: 1

  update: (answer) ->
    if answer.question._id isnt @holdingAnswer.question._id
      throw new Error 'answer is not on pitcher'
    @network.changeNode
      id: @holdingAnswer.question._id
      radius: answer.radius
      fillColor: "url(#color_#{answer.question.index})"
      strokeWidth: 0

  free: ->
    @network.removeLink
      sourceId: 'pitcher'
      targetId: @holdingAnswer.question._id
    @holdingAnswer = null

  getAnswer: ->
    @holdingAnswer


class Field
  constructor: (ourNetwork) ->
    @network = ourNetwork
    #init instance vars
    @nodeIds = []
    @xMax = null

  buildAndCatch: (answer) ->
    #debugger if answer.status is 'skipped'
    question = answer.question
    node =
      id: question._id
      qIndex: question.index
      x: @network.width
      y: @network.height/2
      radius: answer.radius
      fillColor: "url(#color_#{answer.question.index})"
    @network.addNode node
    @catch answer
    return

  catch: (answer) ->
    #debugger if answer.status is 'skipped'
    ldMin = linkDistanceScale(answer.value)
    question = answer.question
    @network.changeNode
      id: question._id
      radius: answer.radius
      fillColor: "url(#color_#{answer.question.index})"
      strokeWidth: 0
      xMax: @xMax if @xMax?
      xMaxT: Date.now()+3000
      isFavorite: answer.isFavorite
      isDead: answer.status isnt 'valid'

    @network.addLink
      sourceId: question._id
      targetId: question.cluster+'_min'
      linkDistance: ldMin
    @network.addLink
      sourceId: question._id
      targetId: question.cluster+'_max'
      linkDistance: linkDistanceMax-ldMin
    @nodeIds.push question._id
    return

  update: (answer) ->
    #debugger if answer.status is 'skipped'
    question = answer.question
    @network.changeNode
      id: question._id
      radius: answer.radius
      fillColor: "url(#color_#{answer.question.index})"
      strokeWidth: 0
      xMax: @xMax if @xMax?
      isFavorite: answer.isFavorite
      isDead: answer.status isnt 'valid'

    ldMin = linkDistanceScale(answer.value)
    @network.changeLink
      sourceId: question._id
      targetId: question.cluster+'_min'
      linkDistance: ldMin
    @network.changeLink
      sourceId: question._id
      targetId: question.cluster+'_max'
      linkDistance: linkDistanceMax-ldMin
    return

  free: (answer) ->
    question = answer.question
    @network.removeLink
      sourceId: question._id
      targetId: question.cluster+'_min'
    @network.removeLink
      sourceId: question._id
      targetId: question.cluster+'_max'
    @network.changeNode
      id: question._id
      removeXMax: true

    index = @nodeIds.indexOf question._id
    @nodeIds.splice(index, 1)
    return

  setXMax: (max) ->
    @xMax = max
    self = @
    @nodeIds.forEach (id) ->
      self.network.changeNode
        id: id
        xMax: max


class Chain
  radius: 12
  linkDistance: 1
  strokeWidth:2
  strokeColor:'#000'
  constructor: (ourNetwork) ->
    @network = ourNetwork
    #init instance vars
    @items = []
    @nodeIds = []
    #draw chain top & bottom
    @network.addNode
      id: 'chain_top'
      fixed: true
      x: @network.width#-@radius/2
      y: 0
      radius: 0
      #fillColor: '#000'
    @network.addNode
      id: 'chain_bottom'
      fixed: true
      x: @network.width#-@radius/2
      y: @network.height#-@radius/2
      radius: 0
      #fillColor: '#000'


  buildAndCatch: (answer) ->
    node =
      id: answer.question._id
      qIndex: answer.question.index
      x: @network.width-(@radius/2)
      y: @radius*2*@linkDistance*2*@nodeIds.length
    @network.addNode node
    @catch answer

  catch: (answer) ->
    if answer.status is 'new'
      @network.changeNode
        id: answer.question._id
        radius: @radius
        fillColor: "url(#color_#{answer.question.index})"
        strokeWidth: 0
    else if answer.status is 'skipped'
      @network.changeNode
        id: answer.question._id
        radius: @radius
        radius: @radius-2.5
        fillColor: "#fff"
        strokeColor: "url(#color_#{answer.question.index})"
        strokeWidth: 5

    #link up
    targetId = null
    if @nodeIds.length is 0
      @network.addLink
        sourceId: answer.question._id
        targetId: 'chain_top'
        linkDistance: @linkDistance
    else
      @network.addLink
        sourceId: answer.question._id
        targetId: @nodeIds[@nodeIds.length-1]
        linkDistance: @linkDistance
        strokeWidth: @strokeWidth
        strokeColor: @strokeColor
    @nodeIds.push answer.question._id
    @items.push answer


    #relinkBottom
    if @nodeIds.length > 1
      @network.removeLink
        sourceId: "chain_bottom"
        targetId: @nodeIds[@nodeIds.length-2]
    @network.addLink
      sourceId: 'chain_bottom'
      targetId: @nodeIds[@nodeIds.length-1]
      linkDistance: @linkDistance
    return

  shift: ->
    nodeId = @nodeIds.shift()

    if nodeId?
      if @nodeIds.length > 0
        #link new top to anchor
        @network.addLink
          sourceId: @nodeIds[0]
          targetId: 'chain_top'
          linkDistance: @linkDistance
        #remove link from next to this
        @network.removeLink
          sourceId: @nodeIds[0]
          targetId: nodeId

      #remove link from this to top
      @network.removeLink
        sourceId: nodeId
        targetId: 'chain_top'

      #remove link from bottom if this was last
      if @nodeIds.length is 0
        @network.removeLink
          sourceId: 'chain_bottom'
          targetId: nodeId

    return @items.shift()

  pop: ->
    nodeId = @nodeIds.pop()

    if nodeId?
      lastIndex = @nodeIds.length-1
      if @nodeIds.length > 0
        #link new bottom to anchor
        @network.addLink
          sourceId: 'chain_bottom'
          targetId: @nodeIds[lastIndex]
          linkDistance: @linkDistance
        #remove link from this to previous
        @network.removeLink
          sourceId: nodeId
          targetId: @nodeIds[lastIndex]

      #remove link from this to bottom
      @network.removeLink
        sourceId: 'chain_bottom'
        targetId: nodeId

      #remove link from top if this was last
      if @nodeIds.length is 0
        @network.removeLink
          sourceId: nodeId
          targetId: 'chain_top'

    return @items.pop()

  free: (answer) ->
    nodeId = answer.question._id
    index = @nodeIds.indexOf nodeId

    if index is 0
      return @shift()
    else if index is @nodeIds.length-1
      return @pop()
    else
      #stitch together new neighbours
      @network.addLink
        sourceId: @nodeIds[index+1]
        targetId: @nodeIds[index-1]
        linkDistance: @linkDistance
        strokeWidth: @strokeWidth
        strokeColor: @strokeColor
      #remove link from this to previous
      @network.removeLink
        sourceId: nodeId
        targetId: @nodeIds[index-1]
      #remove link from next to this
      @network.removeLink
        sourceId: @nodeIds[index+1]
        targetId: nodeId
      @nodeIds.splice index, 1
      return @items.splice index, 1


@freakout1 = ->
  i = 0
  interval = Meteor.setInterval ->
    $('#next').click()
    i+=1
    if i > 200
      Meteor.clearInterval interval
  , 50
  return

@freakout2 = ->
  i = 0
  interval = Meteor.setInterval ->
    random = Math.floor(Math.random()*20)
    gotoQuestionIndex random
    i+=1
    if i > 200
      Meteor.clearInterval interval
  , 50
  return

@freakout3 = ->
  i = 0
  interval = Meteor.setInterval ->
    question = Questions.findOne
      index: _questionIndex.get()
    updateAnswer(null, Math.random(), question)

    r = Math.floor(Math.random() * 3)
    if r is 0
      $('.min').click()
    else if r is 1
      $('.max').click()
    else if r is 2
      $('#next').click()

    i+=1
    if i > 30
      Meteor.clearInterval interval
  , 50
  return


_lastUploadTime = null
Template.evaluation.rendered = ->
  #@$("#evaluation").mCustomScrollbar({ theme: 'minimal-dark', mouseWheel: { preventDefault: true }, scrollButtons: { enable: false } })

  #render SVG as PNG
  return if !_network?
  bubblesSVG = d3.select('#'+_network.svgElementId)
    .attr('version', 1.1)
    .attr('xmlns', 'http://www.w3.org/2000/svg')
    .node()
  if !bubblesSVG
    return
  svgAsXML = bubblesSVG.parentNode.innerHTML

  width = _network.width
  height = _network.height
  fieldWidth = getBubblesWidth()+radiusMax
  #scale aspect
  #maxWidth = 1024
  #maxHeight = 768
  #if width > maxWidth
  #  height = maxWidth/width*height
  #  width = maxWidth
  #if height > maxHeight
  #  width = maxHeight/height*width
  #  height = maxHeight
  #fieldWidth = width/_network.width*fieldWidth
  #console.log "width: #{width}  height: #{height}"
  #console.log "fieldWidthScaled: #{fieldWidth}"

  image = new Image
  image.width = width
  image.height = height

  canvas = document.createElement('canvas')
  ctx = canvas.getContext('2d')
  canvas.width = fieldWidth
  canvas.height = height

  image.onload = ->
    ctx.drawImage image, 0, 0, fieldWidth, height, 0, 0, fieldWidth, height
    pngData = canvas.toDataURL()
    $('#mybubbles-preview').attr 'src', pngData

    if _visitId?
      if !_lastUploadTime? or _lastUploadTime < (Date.now() - 5000)
        _lastUploadTime = Date.now()
        console.log "upload"
        Meteor.call "uploadMyBubbles", _visitId, pngData, (error, url) ->
          throwError error if error?

    return

  image.src = 'data:image/svg+xml,' + encodeURIComponent(svgAsXML)


Template.evaluation.events
  # add slide animation to (login) dropdown
  'show.bs.dropdown': (e) ->
    $('.dropdown-menu').first().stop(true, true).slideDown()

  'hide.bs.dropdown': (e) ->
    $('.dropdown-menu').first().stop(true, true).slideUp()


Template.evaluation.helpers
  proPercent: ->
    _proPercent.get()

  showCreateAccount: ->
    user = Meteor.user()
    user and (not user.emails or user.emails.length is 0)

  visit: ->
    Visits.findOne _visitId

  shareData: ->
    title: 'smartervote - bedingungslos.ch'
    url: 'https://bge.patpat.org/myBubbles/'+_visitId
    thumbnail: "https://bge.patpat.org/#{@visit.myBubblesUrl}" if @visit? and @visit.myBubblesUrl?

  topics: ->
    _topics.map (topic) ->
      answers = []
      Object.keys(_answers).forEach (key) ->
        answer = _answers[key]
        if answer.question.topic is topic
          answers.push answer
      title: topic
      pp: Answer.getProPercent(answers)

  topicCSS: ->
    topic = Session.get 'activeTopic'
    if @toString() is topic
      return "active"
    else
      ""

Template.evaluation.events
  "click #gotoQuestions": (evt) ->
    Session.set 'showEvaluation', false

  "click .topic": (evt) ->
    topic = @title.toString()
    if Session.get('activeTopic') is topic
      topic = null
    Session.set 'activeTopic', topic
    Object.keys(_answers).forEach (key) ->
      answer = _answers[key]
      question = answer.question
      if question.topic is topic or topic is null
        _network.changeNode
          id: question._id
          fillOpacity: 1.0
      else
        _network.changeNode
          id: question._id
          fillOpacity: 0.05
