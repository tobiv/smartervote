#Template.newsItem.rendered = ->
#  @$('.content').readmore
#    moreLink: "<a href='#'>#{TAPi18n.__('readmore')}</a>"
#    lessLink: "<a href='#'>#{TAPi18n.__('readless')}</a>"
#    collapsedHeight: 300

Template.newsItem.helpers
  image: ->
    null if !@newsImageId
    NewsImages.findOne @newsImageId
