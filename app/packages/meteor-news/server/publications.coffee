Meteor.publish "news", ->
  News.find()

Meteor.publish "newsItem", (id) ->
  News.find(id)

Meteor.publish "newsImages", ->
  NewsImages.find()
