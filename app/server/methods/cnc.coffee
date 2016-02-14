Meteor.methods
  'deleteAllUserData': ->
    throw new Meteor.Error(400, "you need to log in") unless Meteor.userId()?
    throw new Meteor.Error(403, "admin privileges required") unless Roles.userIsInRole(Meteor.userId(), 'admin')
    Answers.remove({})
    Visits.remove({})
    MyBubbles.remove({})
