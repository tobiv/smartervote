Meteor.publish "post", (slug) ->
  if @userId? and Roles.userIsInRole @userId, 'admin'
    Posts.find
      slug: slug
  else
    Posts.find
      published: true 
      slug: slug

Meteor.publish "crumbsForPost", (postId) ->
  Crumbs.find
    postId: postId
