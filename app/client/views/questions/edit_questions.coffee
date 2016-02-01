resizeQuestionEditor = ->
  qe = $('#questionEditor')
  parent = qe.parent() 
  qe.width( parent.width() )

Template.editQuestions.rendered = ->
  $(window).resize(resizeQuestionEditor)
  resizeQuestionEditor()
  @autorun ->
    sqId = Session.get 'selectedQuestionId'
    sq = $(".selectedQuestion")
    qe = $("#questionEditor")
    if sq.length > 0 and qe.length > 0
      if $(document).width() > 992 #BS breakpoint
        qe.css("margin-top", sq.offset().top-62)
      else
        qe.css("margin-top", "")

Template.editQuestions.destroyed = ->
  $(window).off("resize", resizeQuestionEditor)


Template.editQuestions.helpers
  hasQuestions: ->
    Questions.find().count() > 0

  questions: ->
    Questions.find {},
      sort:
        index: 1

  selectedQuestion: ->
    id = Session.get 'selectedQuestionId'
    Questions.findOne
      _id: id

  #this: selectedQuestion
  index: ->
    @index+1

  #this: selectedQuestion
  questionMetaSchema: ->
    new SimpleSchema(@getMetaSchemaDict())
 

Template.editQuestions.events
  "click #addQuestion": (evt) ->
    question =
      label: " "
      type: "scale"
      optional: true
      min: 0
      max: 1
      step: 0.1
      start: 0.5
    Meteor.call "insertQuestion", question, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id

  "click #copyQuestion": (evt) ->
    sid = Session.get 'selectedQuestionId'
    selectedQuestion = Questions.findOne
      _id: sid
    delete selectedQuestion._id
    delete selectedQuestion.index
    Meteor.call "insertQuestion", selectedQuestion, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id

  "click #removeQuestion": (evt) ->
    sid = Session.get 'selectedQuestionId'
    if confirm("Delete Question?")
      Meteor.call "removeQuestion", sid, (error, _id) ->
        throwError error if error?
        Session.set 'selectedQuestionId', null


#########################################################
# edit Questions

AutoForm.hooks
  questionsForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      @done()
      false


Template.editQuestion.helpers
  #this question=question
  index: ->
    @question.index+1

  #this question=question
  questionCSS: ->
    if @question._id is Session.get("selectedQuestionId")
      "selectedQuestion"
    else
      ""

Template.editQuestion.events
  "click .question": (evt) ->
    Session.set 'selectedQuestionId', @question._id


sortableTimeout = null
Template.editQuestion.rendered = ->
  Meteor.clearTimeout(sortableTimeout) if sortableTimeout?
  sortableTimeout = Meteor.setTimeout( ->
    $(".questions").sortable
      items: ".question:not(.ui-sortable-disabled)"
      #helper : 'clone'
      #don't trust ui! after (d'n'd) the DOM is updated
      #correctly by blaze ui.item will still hold
      #the old item with the old index! WTF!
      #so we can't use ui.item.data("index")
      start: (e, ui) ->
        index = ui.item.index()
        #console.log index
        $(this).attr('data-pIndex', index)
        return
      stop: (event, ui) -> # fired when an item is dropped
        newIndex = parseInt(ui.item.index())
        oldIndex = parseInt($(this).attr('data-pIndex'))
        #console.log " #{oldIndex} -> #{newIndex}"
        if newIndex is oldIndex
          $(".questions").sortable("cancel")
        else
          Meteor.call "moveQuestion", oldIndex, newIndex, (error) ->
            if error?
              $(".questions").sortable("cancel")
              throwError error
            else
              $(".questions").sortable("refresh")
        return
    , 800)

