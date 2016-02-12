@MyBubbles = new (FS.Collection)("my_bubbles",
  stores: [
    new FS.Store.GridFS("my_bubbles")
  ]
)

MyBubbles.allow
  download: (userId)->
    true
