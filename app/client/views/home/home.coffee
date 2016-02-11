Template.home.rendered = ->
  @$('.grid').masonry( { itemSelector: '.grid-item', columnWidth: '.grid-sizer', percentPosition: true } )
  

Template.home.helpers
  news: ->
    lang = TAPi18n.getLanguage()
    News.find
      languages: lang
    ,
      sort:
        createdAt: -1
