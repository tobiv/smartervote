AccountsAnonymous.onAbandoned (anon) ->
  user = Meteor.user()
  console.log "transfer data from anon:#{anon._id} to existing user:#{user._id}"

  newestVisit = Visits.find(
    userId: anon._id
  ,
    sort: {createdAt: -1, limit: 1}
  ).fetch()[0]

  if newestVisit?
    numAnswers = Answer.find(
      visitId: newestVisit._id
    ).count()
    if numAnswers < 5
      Answers.remove
        visitId: newestVisit._id
      Visits.remove newestVisit._id

  Visits.update
    userId: anon._id
  ,
    $set:
      userId: user._id

  #remove anon
  Meteor.users.remove anon._id
  return
