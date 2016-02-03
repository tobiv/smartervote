AccountsAnonymous.onAbandoned (anon) ->
  user = Meteor.user()
  console.log "transfer data from anon:#{anon._id} to existing user:#{user._id}"

  Visits.update
    userId: anon._id
  ,
    $set:
      userId: user._id

  #remove anon
  Meteor.users.remove anon._id
  return
