_timeout = null

Template.myBlogIndex.rendered = ->
  @autorun ->
    TAPi18n.getLanguage()
    Meteor.clearTimeout _timeout
    _timeout = Meteor.setTimeout ->
      $('#main').imagesLoaded( () ->
        $('.grid').masonry().masonry('destroy')
        $('.grid').masonry({ itemSelector: '.grid-item', columnWidth: '.grid-sizer', percentPosition: true })
        $('.grid').masonry('layout')
      )
    , 300