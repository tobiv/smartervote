Template.home.helpers
  news: ->
    lang = TAPi18n.getLanguage()
    News.find
      languages: lang
    ,
      sort:
        createdAt: -1

Template.home.events
  #open links in news in a new page
  'click .grid a': (evt) ->
    href = evt.target.href
    if href? and href.indexOf(Meteor.absoluteUrl()) is -1 
      evt.preventDefault()
      window.open href, '_blank'
      return false
    true
