Template.myBlogIndex.rendered = ->
  @autorun ->
    TAPi18n.getLanguage()
    $('#main').imagesLoaded( () ->
      $('.grid').masonry().masonry('destroy')
      $('.grid').masonry({ itemSelector: '.grid-item', columnWidth: '.grid-sizer', percentPosition: true })
      $('.grid').masonry('layout')
    )
