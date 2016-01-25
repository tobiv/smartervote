@Session_ =
  toggle: (id, obj) ->
    a = null
    Tracker.nonreactive ->
      a = Session.get id
    a ?= []
    if (index = _.indexOf(a, obj)) > -1
      a.splice index, 1
    else
      a.push obj
    Session.set id, a

  push: (id, obj) ->
    a = null
    Tracker.nonreactive ->
      a = Session.get id
    a ?= []
    a.push obj
    Session.set id, a

  pop: (id) ->
    a = null
    Tracker.nonreactive ->
      a = Session.get id
    a ?= []
    r = a.pop()
    Session.set id, a
    r
