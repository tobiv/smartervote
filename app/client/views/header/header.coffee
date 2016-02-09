Template.header.helpers
  activeRouteClass: (routeNames...)->
    args = Array::slice.call(routeNames, 0)
    args.pop()
    active = _.any(args, (name) ->
      Router.current() and Router.current().route and Router.current().route.getName() is name
    )
    return "active" if active
    ""
    
Template.header.events
  'click .site-menu-toggle': () ->
    $('#overlay-menu').addClass('in')
