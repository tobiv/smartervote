class @Question
  constructor: (doc) ->
    _.extend this, doc

  getSchemaDict: ->
    s = _.pickDeep @, 'type', 'label', 'optional', 'min', 'max', 'options', 'options.label', 'options.value'
    s.type = Number
    s.decimal = true
    s.autoform =
      type: "noUiSlider"
      step: @step
      #start: ((@max-@min)/2)
      labelLeft: @minLabel if @minLabel?
      labelRight: @maxLabel if @maxLabel?
    delete s.options
    s


  getMetaSchemaDict: ->
    label:
      label: "Question / statement"
      type: String
      optional: false
      autoform:
        type: "textarea"
    info:
      label: "Info"
      type: String
      optional: true
      autoform:
        type: "textarea"
        rows: 10
    cluster:
      label: "Cluster"
      type: String
    hrid:
      label: "HRID"
      type: String
      optional: true
    minLabel:
      label: "min label"
      type: String
      optional: true
    maxLabel:
      label: "max label"
      type: String
      optional: true
    isOneSided:
      label: "one sided"
      type: Boolean
    isOnlyNegative:
      label: "only negative"
      type: Boolean
    isLeftPositiv:
      label: "left positiv"
      type: Boolean


@Questions = new Meteor.Collection("questions",
  transform: (doc) ->
    new Question(doc)
)

Questions.before.insert BeforeInsertTimestampHook
Questions.before.update BeforeUpdateTimestampHook

#TODO check consistency
Questions.allow
  insert: (userId, doc) ->
    Roles.userIsInRole userId, 'admin'
  update: (userId, doc, fieldNames, modifier) ->
    Roles.userIsInRole userId, 'admin'
  remove: (userId, doc) ->
    Roles.userIsInRole userId, 'admin'

Meteor.methods
  insertQuestion: (question) ->
    throw new Meteor.Error(400, "you need to log in") unless Meteor.userId()?
    throw new Meteor.Error(403, "admin privileges required") unless Roles.userIsInRole(Meteor.userId(), 'admin')
    check(question.label, String)
    check(question.type, String)

    question.index = Questions.find().count()

    #TODO filter question atters
    _id = Questions.insert question
    _id


  removeQuestion: (_id) ->
    throw new Meteor.Error(400, "you need to log in") unless Meteor.userId()?
    throw new Meteor.Error(403, "admin privileges required") unless Roles.userIsInRole(Meteor.userId(), 'admin')
    check(_id, String)
    question = Questions.findOne _id

    Questions.remove _id

    Questions.update
      index: { $gt: question.index }
    ,
      $inc: { index: -1 }
    ,
      multi: true


  moveQuestion: (oldIndex, newIndex) ->
    throw new Meteor.Error(400, "you need to log in") unless Meteor.userId()?
    throw new Meteor.Error(403, "admin privileges required") unless Roles.userIsInRole(Meteor.userId(), 'admin')
    check(oldIndex, Match.Integer)
    check(newIndex, Match.Integer)

    question = Questions.findOne
      index: oldIndex
    throw new Meteor.Error(400, "question with index #{oldIndex} not found.") unless question?

    Questions.update
      index: { $gt: oldIndex }
    ,
      $inc: { index: -1 }
    ,
      multi: true
    Questions.update
      index: { $gte: newIndex }
    ,
      $inc: { index: 1 }
    ,
      multi: true
    Questions.update
      _id: question._id
    ,
      $set: { index: newIndex}
    null
