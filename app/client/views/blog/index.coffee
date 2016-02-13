_timeout = null

Template.myBlogIndex.rendered = ->
  @autorun ->
    TAPi18n.getLanguage()
    Meteor.clearTimeout _timeout
    _timeout = Meteor.setTimeout ->
      try
        $('.grid').masonry('destroy')
        $('.grid').masonry({ itemSelector: '.grid-item', columnWidth: '.grid-sizer', percentPosition: true })
        $('.grid').masonry('layout')
      catch e
        # nüt
    , 200