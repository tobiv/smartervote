Template.errors.helpers
  errors: ->
    Errors.find()

Template.error.rendered = ->
  window.scrollTo(0,0)
  error = @data
  Meteor.defer ->
    Errors.update error._id,
      $set:
        seen: true

    return

  return
