Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"
  notFoundTemplate: "not_found"
  i18n:
    exclude: [
      '\/admin', '\/blog', '\/img\/'
    ]
    server:
      exclude:
        sitemap: '^\/sitemap\.xml'


if Meteor.isClient
  AccountsEntry.config
    homeRoute: '/home' #redirect to this path after sign-out
    dashboardRoute: '/home'  #redirect to this path after sign-in
    passwordSignupFields: 'EMAIL_ONLY'


Router.route '/',
  name: 'home'
  waitOn: ->
    [
      Meteor.subscribe('news')
      Meteor.subscribe('newsImages')
    ]
  action: ->
    @render 'home'

Router.route 'smartervote',
  layoutTemplate: 'layoutSmartervote'
  waitOn: ->
    [
      Meteor.subscribe('questions')
      Meteor.subscribe('visits')
      Meteor.subscribe('answers')
    ]
  action: ->
    @render 'smartervote'

Router.route 'myBubbles/:id',
  waitOn: ->
    Meteor.subscribe('visit', @params.id)
  data: ->
    Visits.findOne(@params.id)
  seo:
    image: -> 
      Meteor.absoluteUrl()+@data().myBubblesUrl
  action: ->
    @render 'myBubbles'

Router.route 'smartervote-content',
  waitOn: ->
    Meteor.subscribe('questions')
  action: ->
    @render 'questionOverview'

#admin routes
Router.route '/admin/users',
  waitOn: ->
    Meteor.subscribe('users')
  action: ->
    @render 'users'

Router.route '/admin/editQuestions',
  waitOn: ->
    Meteor.subscribe('questions')
  action: ->
    @render 'editQuestions'

Router.route '/admin/cnc',
  waitOn: ->
    Meteor.subscribe('questions')
  action: ->
    @render 'cnc'

Router.route '/account',
  action: ->
    @render 'account'
