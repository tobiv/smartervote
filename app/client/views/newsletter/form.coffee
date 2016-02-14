_status = new ReactiveVar ''
Template.newsletterForm.helpers
  status: ->
    _status.get()

Template.newsletterForm.events
  'submit': (evt, tmpl) ->
    evt.preventDefault()
    email = tmpl.$('input').val()
    if !email
      return
    _status.set 'fa-spinner fa-spin' 
    lang = TAPi18n.getLanguage()
    Meteor.call 'subscribeToNewsletter', email, lang, (error, result) ->
      if error?
        throwError error 
        _status.set('fa-bolt')
      else
        _status.set('fa-check')
    false
