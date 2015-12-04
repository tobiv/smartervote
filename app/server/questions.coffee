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
      label: columns[1]
      minLabel: columns[2]
      maxLabel: columns[3]
      type: "scale"
      optional: true
      min: 0
      max: 1
      step: 0.1
      start: 0.5
      break: (lineCounter%5 is 0)
    console.log question
    Questions.insert question
    return
  )
