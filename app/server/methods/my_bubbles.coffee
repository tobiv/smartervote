Future = Npm.require('fibers/future')
Meteor.methods
  'uploadMyBubbles': (visitId, pngData) ->	
    check visitId, String
    check pngData, String

    throw new Meteor.Error(400, "you need to login to reset a visit") unless Meteor.userId()?

    visit = Visits.findOne
      _id: visitId
      userId: Meteor.userId()
    throw new Meteor.Error(400, "visit not found") unless visit?

    pngData = pngData.replace(/^data:image\/png;base64,/, "")

    #insert file into collection and return download url
    future = new Future
    buffer = new Buffer(pngData, "base64")
    newFile = new FS.File
    newFile.name "#{visitId}.png"
    newFile.metadata =
      visitId: visitId
      createdAt: Date.now()
      userId: Meteor.userId()
    newFile.attachData buffer, { type: 'image/png' }, (error) ->
      if error?
        future.throw error
        return
      MyBubbles.insert newFile, (err, fileObj) ->
        if err?
          future.throw err
          return
        urlRetrieveCount = 0
        onStored = Meteor.bindEnvironment((->
          if urlRetrieveCount > 20
            future.throw new Error('Too much url retrieval attempts for MyBubbles.')
            return
          url = fileObj.url { auth: false }
          if url
            future.return url
          else
            urlRetrieveCount++
            setTimeout onStored, 500
          return
        ), (error) ->
          future.throw error
          return
        )
        fileObj.once 'stored', onStored

    future.wait()
    url = future.get()

    Visits.update visitId,
      $set:
        myBubblesUrl: url

    url

