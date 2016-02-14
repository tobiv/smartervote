Template.cnc.events
  'click #deleteAndImportQuestions': (evt) ->
    if confirm('are you sure')
      if confirm('are you really sure')
        Meteor.call 'deleteAndImportQuestions', (error) ->
          throwError error if error?

  'click #deleteAllUserData': (evt) ->
    if confirm('are you sure')
      if confirm('are you really sure')
        Meteor.call 'deleteAllUserData', (error) ->
          throwError error if error?
