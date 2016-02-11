

Template.home.helpers
  news: ->
    lang = TAPi18n.getLanguage()
    News.find
      languages: lang
    ,
      sort:
        createdAt: -1
