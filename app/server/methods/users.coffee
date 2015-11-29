Meteor.methods
  createPseudoUser: ->
    _id = null
    tries = 0
    failed = false
    username = null
    password = null
    loop
      try
        failed = false
        username = (new Meteor.Collection.ObjectID)._str
        password = (new Meteor.Collection.ObjectID)._str
        Accounts.createUser
          username: username
          password: password
      catch e
        failed = true
        console.log "Error: createPseudoUser"
        console.log e
      finally
        break if !failed
        console.log "failed: "+failed
        tries += 1
        break if _id or tries >= 5
    throw new Meteor.Error(500, "Can't create pseudo user, id space seems to be full.") if failed
    return {
      username: username
      password: password
    }
