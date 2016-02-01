class @Question
  constructor: (doc) ->
    _.extend this, doc

  getSchemaDict: ->
    s = _.pickDeep @, 'type', 'label', 'optional', 'min', 'max', 'options', 'options.label', 'options.value'
    switch @type
      when "scale"
        s.type = Number
        s.decimal = true
        s.autoform =
          type: "noUiSlider"
          step: @step
          #start: ((@max-@min)/2)
          labelLeft: @minLabel if @minLabel?
          labelRight: @maxLabel if @maxLabel?
      when "text"
        s.type = String
        s.autoform =
          type: "textarea"
      when "boolean"
        s.type = Boolean
        s.autoform =
          type: "boolean-radios"
      when "multipleChoice"
        s.autoform =
          options: @choices
        if @mode is "radio"
          s.type = Number
          s.autoform.type = "select-radio-inline"
        else if @mode is "checkbox"
          s.type = [Number]
          s.autoform.type = "select-checkbox-inline"
    delete s.options
    s


  getMetaSchemaDict: ->
    schema =
      label:
        label: "Question / statement"
        type: String
        optional: false
        autoform:
          type: "textarea"
      type:
        label: "Type"
        type: String
        autoform:
          type: "select"
          options: ->
            [
              {label: "Scale", value: "scale"},
              {label: "Text", value: "text"},
              {label: "Boolean", value: "boolean"},
              {label: "Multiple Choice", value: "multipleChoice"},
            ]
      break:
        label: "break after this question"
        type: Boolean

    if @type is "scale"
      _.extend schema,
        minLabel:
          label: "min label"
          type: String
          optional: true
        maxLabel:
          label: "max label"
          type: String
          optional: true
        #min:
        #  label: "min"
        #  type: Number
        #  decimal: true
        #max:
        #  label: "max"
        #  type: Number
        #  decimal: true
        #step:
        #  label: "step"
        #  type: Number
        #  decimal: true
        #start:
        #  label: "start"
        #  type: Number
        #  optional: false
        #  decimal: true

    if @type is "multipleChoice"
      _.extend schema,
        mode:
          label: "Mode"
          type: String
          autoform:
            type: "select-radio-inline"
            options: [
              label: "single selection (radios)"
              value: "radio"
            ,
              label: "multiple selection (checkboxes)"
              value: "checkbox"
            ]
        choices:
          type: [Object]
          label: "Choices"
          minCount: 1
        'choices.$.label':
          type: String
          optional: true
        'choices.$.value':
          type: Number
    schema


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
