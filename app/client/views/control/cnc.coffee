Template.cnc.events
  'click #deleteAllAnswers': (evt) ->
    if confirm('are you sure')
      if confirm('are you really sure')
        Meteor.call 'deleteAllAnswers', (error) ->
          throwError error if error?

  'click #deleteAllVisits': (evt) ->
    if confirm('are you sure')
      if confirm('are you really sure')
        Meteor.call 'deleteAllVisits', (error) ->
          throwError error if error?
