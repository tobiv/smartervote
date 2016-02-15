Meteor.publish "news", ->
  News.find({}, { limit: 8 })

Meteor.publish "newsItem", (id) ->
  News.find(id)

Meteor.publish "newsImages", ->
  NewsImages.find()
