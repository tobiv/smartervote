if Meteor.isServer
  appDump.allow = ->
    if Roles.userIsInRole @user, ['admin']
      return true
    return false
