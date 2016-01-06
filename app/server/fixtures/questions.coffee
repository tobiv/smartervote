fs = Npm.require('fs')
readline = Npm.require('readline')

#Questions.remove({})
#Answers.remove({})
#Visits.remove({})

if Questions.find().count() is 0
  i=0
  fs.createReadStream(process.env.PWD+"/public/questions.csv").pipe( csv(
    headers: false
    delimiter: ';'
    ignoreEmpty: true
  ))
  .on('data', Meteor.bindEnvironment (columns) ->
    i+=1
    return if i is 1
    question =
      index: parseInt(columns[0])-1
      cluster: columns[1]
      title: columns[2]
      label: columns[3]
      break: (i%5 is 0)
      info: columns[7].replace(/"/g, '').replace(/\n/g, '<br>') if columns[7]?
      optional: true
    boolean = columns[4].length > 0
    if boolean
      _.extend question,
      type: "boolean"
    else
      _.extend question,
      minLabel: columns[5]
      maxLabel: columns[6]
      type: "scale"
      min: -0.5
      max: 0.5
      step: 0.1
      start: 0
    console.log question
    Questions.insert question
    return
  ).on 'end', Meteor.bindEnvironment ->
    console.log Questions.find().count()+" questions imported"
    return
