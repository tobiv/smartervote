Template.newsListItem.helpers
  image: ->
    null if !@newsImageId
    NewsImages.findOne @newsImageId
