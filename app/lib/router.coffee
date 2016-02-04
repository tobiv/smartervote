Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"
  notFoundTemplate: "not_found"
  i18n:
    exclude:
      adminPaths: '^\/admin'
    server:
      exclude: 
        sitemap: '^\/sitemap\.xml'

Router.onBeforeAction ->
  AccountsEntry.signInRequired(@)
, 
	only: ['users', 'editQuestions', 'cnc']

if Meteor.isClient
  AccountsEntry.config
    homeRoute: '/home' #redirect to this path after sign-out
    dashboardRoute: '/home'  #redirect to this path after sign-in
    passwordSignupFields: 'EMAIL_ONLY'


Router.route '/',
	name: 'home'
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
	action: ->
		@render 'myBubbles'

Router.route 'questionOverview',
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


