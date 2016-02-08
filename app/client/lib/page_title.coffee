Meteor.startup ->
  Tracker.autorun ->
    if document? and document.title?
      document.title = TAPi18n.__ 'pageTitle'
