@News = new Meteor.Collection("news")

News.before.insert BeforeInsertTimestampHook
News.before.update BeforeUpdateTimestampHook

News.allow
  insert: (userId, doc) ->
    Roles.userIsInRole(userId, 'admin')
  update: (userId, doc, fieldNames, modifier) ->
    Roles.userIsInRole(userId, 'admin')
  remove: (userId, doc) ->
    Roles.userIsInRole(userId, 'admin')

schema = new SimpleSchema(
  createdAt:
    type: Number
    decimal: true
    optional: true
  updatedAt:
    type: Number
    decimal: true
    optional: true
  title:
    type: String
    label: 'Title'
  content:
    type: String
    label: 'Content'
    autoform:
      type: "medium"
      #type: "textarea"
      #rows: 10
  languages:
    type: [String]
    min: 1
    autoform:
      type: "select-checkbox-inline"
      options: ->
        [
          {label: "DE", value: "de"}
          {label: "FR", value: "fr"}
          {label: "IT", value: "it"}
          {label: "EN", value: "en"}
        ]
  newsImageId:
    type: String
    label: 'Image'
    optional: true
    autoform:
      afFieldInput:
        type: 'fileUpload'
        collection: 'NewsImages'
        label: 'Choose file'
  publishedAt:
    type: Date
    label: "published at"
    autoform:
      afFieldInput: 
        type: "bootstrap-datetimepicker"
)
News.attachSchema schema


@NewsImages = new (FS.Collection)("news_images",
  stores: [
    new FS.Store.GridFS("news_images")
  ]
)

NewsImages.allow
  insert: (userId, doc) ->
    Roles.userIsInRole(userId, 'admin')
  download: (userId)->
    true
