fs = require "fs"
assert = require "assert"

async = require "async"
should = require "should"

{Store} = require "../src/store"

utils = require "../src/utils"

_ = require "underscore"

config = require "./config"


models = 
	person:
		indexes:
			name: ["string", (data) -> data.name]
			age: ["int", (data) -> data.age]
		# validator: null # For later

data1 =
	key: utils.uuid()
	kind: "person"
	name: "Jorn van Dijk"
	age: 27
	length: 184

data2 =
	key: utils.uuid()
	kind: "person"
	name: "Koen Bok"
	age: 29
	length: 184

data3 =
	key: utils.uuid()
	kind: "person"
	name: "Dirk Stoop"
	age: 32
	length: 179

_.map _.keys(config.backends), (backendName) ->
	backend = config.backends[backendName]
	
	describe "Store.#{backendName}", ->
		describe "#simple", ->
		
			store = new Store backend, models

			it "should do drop", (done) ->
				store.destroy done

			it "should create the store without error", (done) ->
				store.create done

			it "should create the store without error 2", (done) ->
				store.create (err, result) ->
					done()
				
			it "should put the data without error", (done) ->
				store.put data1, done
					
			it "should fetch the data without error", (done) ->
				store.get "person", data1.key, (err, result) ->
					data1.should.eql result
					done()
			
			it "should update the data", (done) ->
				data1.age = 28
				store.put data1, ->
					store.get "person", data1.key, (err, result) ->
						data1.should.eql result
						done()
					
			it "should insert multiple", (done) ->
				store.put [data2, data3], done
					
			it "should fetch all", (done) ->
				store.query "person", {}, (err, result) ->
					result.length.should.equal 3
					data1.should.eql result[0]
					data2.should.eql result[1]
					data3.should.eql result[2]
					done()
					
			it "should fetch multiple", (done) ->
				store.get "person", [data1.key, data2.key, data3.key], (err, result) ->
					result.length.should.equal 3
					data1.should.eql result[0]
					data2.should.eql result[1]
					data3.should.eql result[2]
					done()
			
			it "should fetch with a query equal", (done) ->
				store.query "person", {"age =": 32}, (err, result) ->
					result.length.should.equal 1
					data3.should.eql result[0]
					done()
			
			it "should fetch with a query less than", (done) ->
				store.query "person", {"age <": 32}, (err, result) ->
					result.length.should.equal 2
					done()
			
			it "should fetch with a query equal name", (done) ->
				store.query "person", {"name =": "Koen Bok"}, (err, result) ->
					result.length.should.equal 1
					data2.should.eql result[0]
					done()
			
			it "should err if querying on a nonexistent index", (done) ->
				t = -> store.query "person", {"length =": 17}, done
				t.should.throw "No index for person.length"
				done()
				
			n = 10
					
			it "should insert #{n}, one at a time", (done) ->
				async.map [1..n], (c, cb) ->
					data = _.clone(data1) 
					data.key = utils.uuid()
					store.put data, cb
				, done
			
			it "should batch insert #{n}", (done) ->
				data = [1..n].map ->
					data = _.clone(data1) 
					data.key = utils.uuid()
					data
			
				store.put data, done
			
			it "should fetch a lot", (done) ->
				store.query "person", (err, result) ->
					result.length.should.equal 3 + (n*2)
					done()

			
					
			# it "should delete one", (done) ->
			# 	store.del "person", data1.key, (err, result) ->
			# 		store.get "person", data1.key, (err, result) ->
			# 			should.strictEqual null, result
			# 			done()
			# 		
			# it "should delete all", (done) ->
			# 	store.query "person", (err, result) ->
			# 		store.del "person", _.pluck(result, "key"), (err, result) ->
			# 			store.query "person", (err, result) ->
			# 				result.length.should.equal 0
			# 				done()
