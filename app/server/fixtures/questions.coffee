fs = Npm.require('fs')
readline = Npm.require('readline')

#Questions.remove({})
#Answers.remove({})
#Visits.remove({})

if Questions.find().count() is 0
  rd = readline.createInterface(
    input: fs.createReadStream(process.env.PWD+"/public/questions.csv")
    output: process.stdout
    terminal: false)

  lineCounter = 0
  rd.on 'line', Meteor.bindEnvironment( (line) ->
    console.log line
    lineCounter += 1
    return if lineCounter is 1
    columns = line.split(';')
    question =
      index: parseInt(columns[0])-1
      cluster: columns[1]
      title: columns[2]
      label: columns[3]
      break: (lineCounter%5 is 0)
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
        min: 0
        max: 1
        step: 0.1
        start: 0.5
    console.log question
    Questions.insert question
    return
  )
