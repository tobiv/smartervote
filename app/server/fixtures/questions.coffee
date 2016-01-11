#fs = Npm.require('fs')
#readline = Npm.require('readline')
Stream = Npm.require('stream')

#Questions.remove({})
#Answers.remove({})
#Visits.remove({})

if Questions.find().count() is 0
  i=0
  #fs.createReadStream(process.env.PWD+"/private/questions.csv").pipe( csv(
  #request.get(Meteor.absoluteUrl()+'/questions.csv').pipe( csv(
  url = Meteor.absoluteUrl()+'questions.csv'
  console.log "URL: "+url
  HTTP.get url, {auth: "lets:win"}, (error, result) ->
    if error?
      console.log error
      throw new Meteor.Error(error.response.statusCode, "failed to load questions.csv")
    s = new Stream.Readable()
    s._read = -> {}
    s.push(result.content)
    s.push(null)
    s.pipe( csv(
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
        hrid: columns[2]
        label: columns[3]
        info: columns[10].replace(/"/g, '').replace(/\n/g, '<br>') if columns[7]?
        optional: true
        break: (i%5 is 0)
      boolean = columns[4].length > 0
      if boolean
        _.extend question,
        type: "boolean"
      else
        leftPositiv = columns[5].length > 0
        oneSided = columns[6].length > 0
        onlyNegativ = columns[7].length > 0
        console.log "leftPositiv: #{leftPositiv}"
        console.log "oneSided: #{oneSided}"
        console.log "onlyNegativ: #{onlyNegativ}"
        min = -0.5
        max = 0.5
        if not oneSided and leftPositiv
          min = max
          max = -0.5
        if oneSided
          if leftPositiv
            max = 0
            if onlyNegativ
              min = -0.5
            else
              min = 0.5
          else
            min = 0
            if onlyNegativ
              max = -0.5
            else
              max = 0.5
        if not oneSided and onlyNegativ
          console.log "heeeeeeeeeeeeeeeeelp"
        _.extend question,
          type: "scale"
          min: min
          max: max
          minLabel: columns[8]
          maxLabel: columns[9]
          step: Math.abs(max-min)/10
          start: 0
          isOneSided: oneSided
      console.log question
      Questions.insert question
      return
    ).on 'end', Meteor.bindEnvironment ->
      console.log Questions.find().count()+" questions imported"
      return
