Template.questionOverview.helpers
  questions: ->
    Questions.find {},
      sort:
        index: 1

  index: ->
    @index+1
