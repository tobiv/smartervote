Meteor.publish "posts", ->
  if @userId? and Roles.userIsInRole @userId, 'admin'
    Posts.find()
  else
    Posts.find
      published: true 

Meteor.publish "post", (slug) ->
  if @userId? and Roles.userIsInRole @userId, 'admin'
    Posts.find
      slug: slug
  else
    Posts.find
      published: true 
      slug: slug

Meteor.publish "crumbsForPost", (postId, lang) ->
  Crumbs.find
    postId: postId
    lang: lang
