fs = require "fs"
assert = require "assert"

async = require "async"
should = require "should"

{Store} = require "../src/store"

utils = require "../src/utils"

_ = require "underscore"

config = require "./config"


models = 
	post:
		indexes:
			name: ["string", (data) -> data.name]
			tags: ["list:string", (data) -> data.tags]
		# validator: null # For later

data1 =
	key: utils.uuid()
	kind: "post"
	name: "Jorn van Dijk"
	tags: ["nice", "dude"]

data2 =
	key: utils.uuid()
	kind: "post"
	name: "Koen Bok"
	tags: ["nice", "man"]


_.map _.keys(config.backends), (backendName) ->
	backend = config.backends[backendName]
	
	describe "StoreTag.#{backendName}", ->
		describe "#simple", ->
		
			store = new Store backend, models

			it "should do drop", (done) ->
				store.destroy done

			it "should create the store without error", (done) ->
				store.create done

			it "should put the data without error", (done) ->
				store.put [data1, data2], done

			it "should fetch both for the tag nice", (done) ->
				store.query "post", {"tags =": "nice"}, (err, result) ->
					result.length.should.equal 2
					# Can't do this, because the order is not guaranteed
					# data1.should.eql result[1]
					# data2.should.eql result[0]
					done()

			it "should fetch the first for tag dude", (done) ->
				store.query "post", {"tags =": "dude"}, (err, result) ->
					result.length.should.equal 1
					data1.should.eql result[0]
					done()

			it "should fetch the data based on a tag", (done) ->
				store.query "post", {"tags =": "man"}, (err, result) ->
					result.length.should.equal 1
					data2.should.eql result[0]
					done()

			it "should update the data with new tags", (done) ->
				data1.tags = ["mean", "dude"]
				store.put data1, done
			
			it "should fetch only one for the tag nice", (done) ->
				store.query "post", {"tags =": "nice"}, (err, result) ->
					result.length.should.equal 1
					result[0].should.eql data2
					done()

