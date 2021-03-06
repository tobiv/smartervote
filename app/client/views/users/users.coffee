Template.users.helpers
  users: ->
    Meteor.users.find( )

  usersReactiveTableSettings: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: '_id', label: 'ID' }
      { key: 'profile.name', label: 'name' }
      { key: 'emails', label: 'eMail', fn: (v,o) -> if o.emails? then o.emails[0].address else "" }
      { key: 'roles', label: 'roles', fn: (v,o) -> if v? then v.sort().join(', ') else "" }
      { key: 'status.online', label: 'online', tmpl: Template.userStatusTableCell }
      { key: 'buttons', label: '', tmpl: Template.usersTableButtons }
    ]


Template.usersTableButtons.helpers
  systemRoles: ->
    [
      role: "admin"
      icon: "fa-child"
    ]

Template.usersTableButtons.events
  "click .addToRole": (evt)->
    id = $(evt.target).closest("button").data().id
    role = $(evt.target).closest("button").data().role
    Meteor.call "addUserToRoles", id, role, (error) ->
      throwError error.reason if error

  "click .removeFromRole": (evt)->
    evt.stopImmediatePropagation()
    id = $(evt.target).closest("button").data().id
    role = $(evt.target).closest("button").data().role
    if confirm("Really?")
      Meteor.call "removeUserFromRoles", id, role, (error) ->
        throwError error.reason if error

Template.usersTableButtons.helpers
  isInRole: (_id, role) ->
    Roles.userIsInRole(_id, role)
