ensureUserDeferred = null
@ensureUser = ->
  if ensureUserDeferred?
    return ensureUserDeferred.promise

  deferred = Promise.pending()
  ensureUserDeferred = deferred
  if Meteor.userId()?
    deferred.resolve()
  else
    Meteor.call "createPseudoUser", (error, user) ->	
      if error?
        deferred.reject("login with created user failed!")
      Meteor.loginWithPassword user.username, user.password, (error) ->
        if error?
          deferred.reject("login with created user failed!")
        else
          deferred.resolve()
  deferred.promise
