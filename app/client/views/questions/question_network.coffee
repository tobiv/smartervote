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
  clusters = {}
  network = new Network("#bubbles")
  Questions.find().observe
    added: (doc) ->
      doc.id = doc._id
      node = _.pick doc, ['id']
      network.addNode node
      if clusters[doc.cluster]?
        clusters[doc.cluster].push doc
      else
        clusters[doc.cluster] = [doc]
      return
    remove: (doc) ->
      network.removeNode doc._id

  Object.keys(clusters).forEach (c) ->
    network.addNode
      id: c
    clusters[c].forEach (q) ->
      network.addLink
        sourceId: q.id
        targetId: c
        value: 1

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
