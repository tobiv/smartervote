AutoForm.addHooks 'questionForm',
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
  _questionIndex.set( _questionIndex.get()+1 )
  @done()


_numQuestions = new ReactiveVar(0)
_questionIndex = new ReactiveVar(0)
Template.questionNetwork.created = ->
  self = @
  @autorun ->
    _numQuestions.set Questions.find().count()


Template.questionNetwork.rendered = ->
  network = new Network("#bubbles")
  width = network.width()
  height = network.height()

  #get clusters from questions
  clusters = {}
  Questions.find().observe
    added: (doc) ->
      doc.id = doc._id
      #node = _.pick doc, ['id']
      #network.addNode node
      clusters[doc.cluster] ?= []
      clusters[doc.cluster].push doc
      return
    #remove: (doc) ->
    #  network.removeNode doc._id
    #  return

  #draw cluster nodes
  numClusters = Object.keys(clusters).length
  i = 0
  Object.keys(clusters).forEach (c) ->
    x = width/numClusters*i
    network.addNode
      id: c+'_max'
      fixed: true
      x: x
      y: 20
    network.addNode
      id: c+'_min'
      fixed: true
      x: x
      y: height-20
    i+=1

  #DRY
  selectedVisitId = Session.get 'selectedVisitId'
  if selectedVisitId?
    v = Visits.findOne selectedVisitId
  else
    v = Visits.findOne {},
      sort: {createdAt: -1, limit: 1}
  Answers.find
    visitId: v._id
  .observe
    added: (doc) ->
      question = Questions.findOne doc.questionId
      node =
        id: question._id
        x: width
        y: height/2
      network.addNode node

      network.addLink
        sourceId: node.id
        targetId: question.cluster+'_min'
        value: 1
      network.addLink
        sourceId: node.id
        targetId: question.cluster+'_max'
        value: 1

  # draw links from cluster to it's questions/answers
  #Object.keys(clusters).forEach (c) ->
  #  clusters[c].forEach (q) ->
  #    network.addLink
  #      sourceId: q.id
  #      targetId: c
  #      value: 1

Template.questionNetwork.helpers
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

  question: ->
    Questions.findOne
      index: _questionIndex.get()

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
