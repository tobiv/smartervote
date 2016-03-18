Template.newsListItem.rendered = ->
  @autorun ->
    TAPi18n.getLanguage()
    $('#main').imagesLoaded( () ->
      $('.grid').masonry().masonry('destroy')
      $('.grid').masonry({ itemSelector: '.grid-item', columnWidth: '.grid-sizer', percentPosition: true })
      $('.grid').masonry('layout')
    )

Template.newsListItem.helpers
  image: ->
    null if !@newsImageId
    NewsImages.findOne @newsImageId

  excerpt: ->
    null if !@content
    _.str.prune(@content, 200)
