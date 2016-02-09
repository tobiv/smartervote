Template.newsAdmin.helpers
  news: ->
    lang = TAPi18n.getLanguage()
    News.find
      languages: lang
    ,
      sort:
        createdAt: -1

Template.newsAdmin.events
  'click .edit': (evt) ->
    Router.go 'news.edit',
      id: @_id

  'click .add': (evt) ->
    Router.go 'news.new'
