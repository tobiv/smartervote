_timeout = null

Template.newsListItem.rendered = ->
  @autorun ->
    TAPi18n.getLanguage()
    Meteor.clearTimeout _timeout
    _timeout = Meteor.setTimeout -> 
      $('.grid').masonry('destroy')
      $('.grid').masonry({ itemSelector: '.grid-item', columnWidth: '.grid-sizer', percentPosition: true })
      $('.grid').masonry('layout')
    , 200
  
Template.newsListItem.helpers
  image: ->
    null if !@newsImageId
    NewsImages.findOne @newsImageId
