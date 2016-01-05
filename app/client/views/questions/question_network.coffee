
Template.questionNetwork.rendered = ->
	clusters = {}
	network = new Network("#bubbles")
	Questions.find().observe
		added: (doc) ->
			doc.id = doc._id
			node = _.pick doc, ['id']
			network.addNode node
			if clusters[doc.cluster]?
				clusters[doc.cluster].push doc
			else
				clusters[doc.cluster] = [doc]
			return
		remove: (doc) ->
			network.removeNode doc._id

	Object.keys(clusters).forEach (c) ->
		network.addNode
			id: c
		clusters[c].forEach (q) ->
			network.addLink
				sourceId: q.id
				targetId: c
				value: 1
