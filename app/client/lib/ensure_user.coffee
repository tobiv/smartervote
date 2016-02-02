_running = false
@ensureUser = ->
  deferred = Promise.pending()
  if _running
    deferred.reject("ensureUser must run only once at a time")
    return deferred.promise
  _running = true

  ensureUserDeferred = deferred
  if Meteor.userId()?
    _running = false
    deferred.resolve()
  else
    Meteor.call "createPseudoUser", (error, user) ->	
      if error?
        _running = false
        deferred.reject("login with created user failed!")
      Meteor.loginWithPassword user.username, user.password, (error) ->
        if error?
          _running = false
          deferred.reject("login with created user failed!")
        else
          _running = false
          deferred.resolve()
  deferred.promise
