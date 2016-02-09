Router.route '/admin/news',
  waitOn: ->
    [
      Meteor.subscribe('news')
      Meteor.subscribe('newsImages')
    ]
  action: ->
    @render 'newsAdmin'

Router.route '/admin/news/edit/:id',
  name: 'news.edit'
  waitOn: ->
    [
      Meteor.subscribe('newsItem', @params.id)
      Meteor.subscribe('newsImages')
    ]
  data: ->
    News.findOne @params.id
  action: ->
    @render 'newsItemEdit'

Router.route '/admin/news/new',
  name: 'news.new'
  action: ->
    @render 'newsItemEdit'
