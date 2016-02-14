#Template.newsItem.rendered = ->
#  @$('.content').readmore
#    moreLink: "<a href='#'>#{TAPi18n.__('readmore')}</a>"
#    lessLink: "<a href='#'>#{TAPi18n.__('readless')}</a>"
#    collapsedHeight: 300

Template.newsItem.helpers
  image: ->
    null if !@newsImageId
    NewsImages.findOne @newsImageId

Template.newsItem.events
  #open links in news in a new page
  'click a': (evt) ->
    href = evt.target.href
    if href? and href.indexOf(Meteor.absoluteUrl()) is -1 
      evt.preventDefault()
      window.open href, '_blank'
      return false
    true
