Meteor.publish "news", ->
  News.find({}, { sort: {publishedAt: -1}, limit: 8 })

Meteor.publish "newsItem", (id) ->
  News.find(id)

Meteor.publish "newsImages", ->
  NewsImages.find()
