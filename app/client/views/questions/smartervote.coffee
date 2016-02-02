_numQuestions = new ReactiveVar(0)
_questionIndex = new ReactiveVar(-1)
_showInfo = new ReactiveVar(false)
_resizeTrigger = new ReactiveVar(false)

radiusMax = 80
rScale = d3.scale.linear()
rScale.domain [0, 0.5]
rScale.range [20, radiusMax]

linkDistanceMax = 800
linkDistanceScale = d3.scale.linear()
linkDistanceScale.domain [-0.5, 0.5]
linkDistanceScale.range [0, linkDistanceMax]

color = d3.scale.category20b()
colors = [
  '0CFF0C', 'BBFF0C', 'FFF113', 'FFBC13', 'FF8616', 'FF6311', 'FF190B', 'FF1361', 'EE0FFF', '9A15FF', '450FFF', '1437FF', '1B79FF', '13BBFF', '19EFFF', '19FF81', 'FF74E8', 'FFB669', '85FFC8', 'FF645B', 'B3FF62', 'FF3973'
]

_clusters = []

_network = null
_beforeHoverIndex = null

_chain = null
_pitcher = null
_field = null

_visitId = null
_answers = []
_answerSaver = null

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
  $('#smartervote').css 'min-height', wHeight

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

  toggle = null
  Tracker.nonreactive ->
    toggle = _resizeTrigger.get()
  _resizeTrigger.set !toggle


_clustersAdded = false
upsertClusters = ->
  numClusters = _clusters.length
  bubbles = $('#bubbles')
  width = bubbles.width()-80
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

Template.smartervote.created = ->
  @autorun ->
    _numQuestions.set Questions.find().count()

Template.smartervote.destroyed = ->
  $(window).off("resize", resize)

Template.smartervote.rendered = ->
  #initialize network
  network = new Network("#bubbles-container", radiusMax)
  _network = network

  #jump to question, when clicking on node
  network.onNodeClick (d) ->
    gotoQuestionIndex d.qIndex
    _beforeHoverIndex = null

  #jump to question, when hovering over node
  network.onNodeHover (d) ->
    if d?
      _beforeHoverIndex = _questionIndex.get() if not _beforeHoverIndex?
      _questionIndex.set d.qIndex
    else if _beforeHoverIndex?
      _questionIndex.set _beforeHoverIndex
      _beforeHoverIndex = null

  #get clusters from questions and draw them
  clusters = []
  i = 0
  qs = Questions.find({}, {sort: {index: 1}}).forEach (q) ->
    if clusters.indexOf(q.cluster) is -1
      clusters.push q.cluster
    return
  _clusters = clusters

  _answerSaver = new AnswerSaver()

  upsertClusters()

  #subscribe to resize
  $(window).resize(resize)
  resize()

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

    
  #init network elements
  _chain = new Chain(_network)
  _pitcher = new Pitcher(_network)
  _field = new Field(_network)

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
        if answer.status is 'valid'
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
    goNext()
    Meteor.setTimeout ->
      if _questionIndex.get() is -1
        goNext()
    , 500


Template.smartervote.helpers
  question: ->
    Questions.findOne
      index: _questionIndex.get()

  index: ->
    @question.index+1 if @question?

  proPercent: ->
    @visit.proPercent if @visit?

  showScore: ->
    Session.get 'showScore'

  showInfo: ->
    _showInfo.get()

  activeCSS: (bool) ->
    if @answer?
      if bool and @answer.consent is @question.max
        return "active"
      if !bool and @answer.consent is @question.min
        return "active"
    return ""

Template.smartervote.events
  'click .yes, click .no': (evt, tmpl, val) ->
    evt.target.blur()
    if tmpl.$(evt.target).hasClass("yes")
      consent = @question.max
    else
      consent = @question.min
    updateAnswer(consent, null, @question)
    return

  'slide': (evt, tmpl, val) ->
    importance = parseFloat val
    updateAnswer(null, importance, @question)
    return

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
      qi = _numQuestions.get()-1
    gotoQuestionIndex qi

  'click .showInfo': (evt) ->
    evt.preventDefault()
    _showInfo.set true
    #http://stackoverflow.com/questions/3485365/how-can-i-force-webkit-to-redraw-repaint-to-propagate-style-changes
    #http://stackoverflow.com/questions/8840580/force-dom-redraw-refresh-on-chrome-mac
    $('#header').hide().show(0)
    document.getElementById('header').style.display = 'none'
    document.getElementById('header').offsetHeight
    document.getElementById('header').style.display = ''

  'click .hideInfo': (evt) ->
    evt.preventDefault()
    _showInfo.set false
    $('#header').hide().show(0)

  'click #gotoScore': (evt) ->
    evt.preventDefault()
    Session.set 'showScore', true

  "click #reset": (evt, tmpl) ->
    Meteor.call "resetVisit", _visitId, (error, id) ->
      throwError error if error?
      if Session.get('selectedVisitId')?
        Session.set 'selectedVisitId', id


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
    if qi is _numQuestions.get()
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

  #rescue answers that were once dead
  #then placed in the chain, now on the pitcher again
  #forget about the consent once set
  if consent is null and importance isnt null and newConsent is 0
    newConsent = null

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
        #console.log "back to chain"
        newAnswer.position = "chain"
        _chain.catch newAnswer
        _field.free newAnswer
    else if answer.position is 'chain'
      if newAnswer.status is 'valid'
        #console.log "back to field"
        newAnswer.position = "field"
        _field.catch newAnswer
        _chain.free newAnswer

  if consent isnt null and importance is null #updated consent
    if answer.position is 'pitcher'
      if newAnswer.status is 'valid'
        #console.log "field catch, pitcher free"
        newAnswer.position = "field"
        _field.catch newAnswer
        _pitcher.free()
      else
        #console.log "back to chain"
        newAnswer.position = "chain"
        _chain.catch newAnswer
        _pitcher.free()
    else if answer.position is 'field'
      if newAnswer.status is 'valid'
        _field.update newAnswer
      else
        #console.log "back to chain"
        newAnswer.position = "chain"
        _chain.catch newAnswer
        _field.free newAnswer
    else if answer.position is 'chain'
      if newAnswer.status is 'valid'
        #console.log "back to field"
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
  if newAnswer.status isnt 'skipped'
    _answerSaver.upsertAnswer question._id

class AnswerSaver
  ids = []
  saveTimeout = null
  saving = false
  saveAgain = false
  call = Promise.promisify(Meteor.call, Meteor)
  upsertAnswer: (id) ->
    ids.unshift id
    ids = _.unique ids
    @saveAll()

  saveAll: () ->
    #console.log "saveAll"
    self = @
    if saving
      saveAgain = true
      return
    Meteor.clearTimeout(saveTimeout) if saveTimeout?
    saveTimeout = Meteor.setTimeout ->
      self.doSaveAll()
    , 1000

  doSaveAll: () ->
    #console.log "doSaveAll--"
    idsToPush = _.clone ids
    ids.length = 0
    saving = true
    ensureUser()
      .then( ->
        Promise.each idsToPush, (id)->
          answer = _answers[id]
          answer.visitId = _visitId if _visitId?
          #console.log "saving #{answer.question._id}"
          call('upsertAnswer', answer).then( (answerId)->
            #console.log "#{answerId} saved"
            #console.log answer
            _answers[answer.question._id]._id = answerId
          )
      ).catch( (e) ->
        console.log "exception during doSaveAll"
        console.log e
        Promise.delay(4000).then ->
          idsToPush.forEach (id) ->
            _answerSaver.upsertAnswer id
      ).finally ->
        #console.log "all answers saved"
        saving = false
        if saveAgain
          saveAgain = false
          _answerSaver.saveAll()
    return


class Pitcher
  holdingAnswer = null
  network = null
  constructor: (ourNetwork) ->
    @network = ourNetwork
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
    debugger if holdingAnswer?
    holdingAnswer = answer
    @update answer
    @network.addLink
      sourceId: 'pitcher'
      targetId: answer.question._id
      linkDistance: 1

  update: (answer) ->
    if answer.question._id isnt holdingAnswer.question._id
      throw new Error 'answer is not on pitcher'
    @network.changeNode
      id: holdingAnswer.question._id
      radius: answer.radius
      fillColor: "#"+colors[answer.question.index]

  free: ->
    @network.removeLink
      sourceId: 'pitcher'
      targetId: holdingAnswer.question._id
    holdingAnswer = null

  getAnswer: ->
    holdingAnswer


class Field
  answers = []
  nodeIds = []
  network = null
  constructor: (ourNetwork) ->
    @network = ourNetwork

  buildAndCatch: (answer) ->
    question = answer.question
    node =
      id: question._id
      qIndex: question.index
      x: @network.width()
      y: @network.height()/2
      radius: answer.radius
      fillColor: "#"+colors[question.index]
    @network.addNode node
    @catch answer
    return

  catch: (answer) ->
    ldMin = linkDistanceScale(answer.value)
    question = answer.question
    @network.changeNode
      id: question._id
      radius: answer.radius
      fillColor: "#"+colors[question.index]
      strokeWidth: 0

    @network.addLink
      sourceId: question._id
      targetId: question.cluster+'_min'
      linkDistance: ldMin
    @network.addLink
      sourceId: question._id
      targetId: question.cluster+'_max'
      linkDistance: linkDistanceMax-ldMin
    return

  update: (answer) ->
    question = answer.question
    @network.changeNode
      id: question._id
      radius: answer.radius
      fillColor: "#"+colors[question.index]
      strokeWidth: 0

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
    return


class Chain
  items = []
  nodeIds = []
  network = null
  radius = 12
  linkDistance = 1
  strokeWidth = 2
  strokeColor = '#000'
  constructor: (ourNetwork) ->
    @network = ourNetwork
    #draw chain top & bottom
    @network.addNode
      id: 'chain_top'
      fixed: true
      x: @network.width()#-radius/2
      y: 0
      radius: 0
      #fillColor: '#000'
    @network.addNode
      id: 'chain_bottom'
      fixed: true
      x: @network.width()#-radius/2
      y: @network.height()#-radius/2
      radius: 0
      #fillColor: '#000'


  buildAndCatch: (answer) ->
    node =
      id: answer.question._id
      qIndex: answer.question.index
      x: @network.width()-(radius/2)
      y: radius*2*linkDistance*2*nodeIds.length
    @network.addNode node
    @catch answer

  catch: (answer) ->
    if answer.status is 'new'
      @network.changeNode
        id: answer.question._id
        radius: radius
        fillColor: "#"+colors[answer.question.index]
        strokeWidth: 0
    else if answer.status is 'skipped'
      @network.changeNode
        id: answer.question._id
        radius: radius
        fillColor: d3.rgb("#"+colors[answer.question.index]).darker(2)
        strokeWidth: 0
    else if answer.status is 'dead'
      @network.changeNode
        id: answer.question._id
        radius: radius-2.5
        fillColor: "#fff"
        strokeColor: "#"+colors[answer.question.index]
        strokeWidth: 5

    #link up
    targetId = null
    if nodeIds.length is 0
      @network.addLink
        sourceId: answer.question._id
        targetId: 'chain_top'
        linkDistance: linkDistance
    else
      @network.addLink
        sourceId: answer.question._id
        targetId: nodeIds[nodeIds.length-1]
        linkDistance: linkDistance
        strokeWidth: strokeWidth
        strokeColor: strokeColor
    nodeIds.push answer.question._id
    items.push answer


    #relinkBottom
    if nodeIds.length > 1
      @network.removeLink
        sourceId: "chain_bottom"
        targetId: nodeIds[nodeIds.length-2]
    @network.addLink
      sourceId: 'chain_bottom'
      targetId: nodeIds[nodeIds.length-1]
      linkDistance: linkDistance
    return

  shift: ->
    nodeId = nodeIds.shift()

    if nodeId?
      if nodeIds.length > 0
        #link new top to anchor
        @network.addLink
          sourceId: nodeIds[0]
          targetId: 'chain_top'
          linkDistance: linkDistance
        #remove link from next to this
        @network.removeLink
          sourceId: nodeIds[0]
          targetId: nodeId

      #remove link from this to top
      @network.removeLink
        sourceId: nodeId
        targetId: 'chain_top'

      #remove link from bottom if this was last
      if nodeIds.length is 0
        @network.removeLink
          sourceId: 'chain_bottom'
          targetId: nodeId

    return items.shift()

  pop: ->
    nodeId = nodeIds.pop()

    if nodeId?
      lastIndex = nodeIds.length-1
      if nodeIds.length > 0
        #link new bottom to anchor
        @network.addLink
          sourceId: 'chain_bottom'
          targetId: nodeIds[lastIndex]
          linkDistance: linkDistance
        #remove link from this to previous
        @network.removeLink
          sourceId: nodeId
          targetId: nodeIds[lastIndex]

      #remove link from this to bottom
      @network.removeLink
        sourceId: 'chain_bottom'
        targetId: nodeId

      #remove link from top if this was last
      if nodeIds.length is 0
        @network.removeLink
          sourceId: nodeId
          targetId: 'chain_top'

    return items.pop()

  free: (answer) ->
    nodeId = answer.question._id
    index = nodeIds.indexOf nodeId

    if index is 0
      return @shift()
    else if index is nodeIds.length-1
      return @pop()
    else
      #stitch together new neighbours
      @network.addLink
        sourceId: nodeIds[index+1]
        targetId: nodeIds[index-1]
        linkDistance: linkDistance
        strokeWidth: strokeWidth
        strokeColor: strokeColor
      #remove link from this to previous
      @network.removeLink
        sourceId: nodeId
        targetId: nodeIds[index-1]
      #remove link from next to this
      @network.removeLink
        sourceId: nodeIds[index+1]
        targetId: nodeId
      nodeIds.splice index, 1
      return items.splice index, 1


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
      $('.yes').click()
    else if r is 1
      $('.no').click()
    else if r is 2
      $('#next').click()

    i+=1
    if i > 30
      Meteor.clearInterval interval
  , 50
  return
