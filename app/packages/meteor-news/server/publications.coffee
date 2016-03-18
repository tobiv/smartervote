Meteor.publish "news", ->
  News.find({}, { sort: {publishedAt: -1}, limit: 16 })

Meteor.publish "newsItem", (id) ->
  News.find(id)

Meteor.publish "newsImages", ->
  NewsImages.find()
