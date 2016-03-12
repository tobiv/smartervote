Meteor.startup ->
  Tracker.autorun ->
    Meteor.Piwik.setUserInfo Meteor.userId()
    return
