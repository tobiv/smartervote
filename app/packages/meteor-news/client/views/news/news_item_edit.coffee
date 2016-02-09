Template.newsItemEdit.helpers
  doc: ->
    return @ if @._id?
    null
  type: ->
    return "update" if @._id?
    "insert"

Template.newsItemEdit.events
  "click button.goBack": (evt) ->
    Router.go 'admin.news'
    false

AutoForm.hooks
  newsEdit:
    onSuccess: (operation, result, template) ->
      Router.go 'admin.news'
      false
