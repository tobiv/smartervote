Template.questionOverview.helpers
  questions: ->
    Questions.find {},
      sort:
        index: 1

  index: ->
    @index+1

  label: ->
    lang = TAPi18n.getLanguage()
    if @languages[lang]?
      @languages[lang].label

  info: ->
    lang = TAPi18n.getLanguage()
    if @languages[lang]?
      @languages[lang].info
