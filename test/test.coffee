fs = require "fs"
assert = require "assert"

async = require "async"
should = require "should"

sqlbt = require "../src/sqlbt"
utils = require "../src/utils"


path = "./test.sqlite3"

try fs.unlinkSync path
	
# backend = new sqlbt.SQLiteBackend path
backend = new sqlbt.SQLiteBackend ":memory:"

data =
	kind: "person"
	name: "Koen Bok"
	age: 29
	

# models = []
# models.push
# 	kind: "person"
# 	indexes: [
# 		{type: "string", property: "name"}
# 		{type: "int", property: "age"}
# 	]
# models.push
# 	kind: "product"
# 	indexes: [
# 		{type: "string", property: "name"},
# 		{type: "int", property: "price"}
# 		{type: "int", name: "price-plus-ten", property: (data) -> data.price + 10}
# 	]
# 
# store = new sqlbt.Store backend, models
# 
# store.create ->
# 	console.log "done"



models = 
	person:
		kind: "person"
		indexes:
			name:
				type: "string"
				getter: (o) -> o.name
			age:
				type: "int"
				getter: (o) -> o.age
	product:
		kind: "product"
		indexes:
			name:
				type: "string"
				getter: (o) -> o.name
			price:
				type: "int"
				getter: (o) -> o.age


describe "Backend", ->
	describe "#simple", ->
		
		backend = new sqlbt.SQLiteBackend ":memory:"
		
		it "should do create", (done) ->
			backend.execute "CREATE TABLE man (id INTEGER NOT NULL, name TEXT, PRIMARY KEY (id))", done

		it "should do insert", (done) ->
			async.map ["koen", "dirk", "hugo"], (value, cb) ->
				backend.execute "INSERT INTO man (name) VALUES (?)", value, cb
			, done
			
		it "should do select all", (done) ->
			backend.execute "SELECT * FROM man", (err, result) ->
				result.should.eql [
					{id:1, name:"koen"},
					{id:2, name:"dirk"},
					{id:3, name:"hugo"}
				]
				done()

		it "should do select eq", (done) ->
			backend.execute "SELECT * FROM man WHERE id=?", 1, (err, result) ->
				result.should.eql [{id:1, name:"koen"}]
				done()

		it "should do select in", (done) ->
			backend.execute "SELECT * FROM man WHERE id IN (?, ?)", [1, 2], (err, result) ->
				result.should.eql [
					{id:1, name:"koen"},
					{id:2, name:"dirk"}
				]
				done()
		

describe "Store", ->
	describe "#simple", ->
		
		backend = new sqlbt.SQLiteBackend ":memory:"
		store = new sqlbt.Store backend, [models.person]

		data1 =
			key: utils.uuid()
			kind: "person"
			name: "Jorn van Dijk"
			age: 27

		data2 =
			key: utils.uuid()
			kind: "person"
			name: "Koen Bok"
			age: 29

		data3 =
			key: utils.uuid()
			kind: "person"
			name: "Dirk Stoop"
			age: 32
		
		it "should create the store without error", (done) ->
			store.create done
		
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
				data1.should.eql result[0]
				data2.should.eql result[1]
				data3.should.eql result[2]
				done()
		
		it "should fetch multiple", (done) ->
			store.get "person", [data1.key, data2.key, data3.key], (err, result) ->
				data1.should.eql result[0]
				data2.should.eql result[1]
				data3.should.eql result[2]
				done()




