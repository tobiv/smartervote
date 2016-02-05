Router.route 'pages/:slug',
  waitOn: ->
    Meteor.subscribe('post', @params.slug)
  data: ->
    Posts.findOne {slug: @params.slug}
  action: ->
    @render 'post'
