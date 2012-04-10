fs = require "fs"
assert = require "assert"

async = require "async"
should = require "should"

{Store} = require "../src/store"
{SQLiteBackend} = require "../src/backend.sqlite"
{PostgresBackend} = require "../src/backend.postgres"
{MySQLBackend} = require "../src/backend.mysql"

utils = require "../src/utils"

_ = require "underscore"


path = "./test.sqlite3"

try fs.unlinkSync path

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


# describe "Backend", ->
# 	describe "#simple", ->
# 
# 		it "should do drop", (done) ->
# 			backend.execute "DROP TABLE man", done
# 
# 		it "should do create", (done) ->
# 			backend.execute "CREATE TABLE man (id SERIAL, name TEXT, PRIMARY KEY (id))", done
# 
# 		it "should do insert", (done) ->
# 			async.map ["koen", "dirk", "hugo"], (value, cb) ->
# 				backend.execute "INSERT INTO man (name) VALUES (?)", [value], cb
# 			, done
# 			
# 		it "should do select all", (done) ->
# 			backend.execute "SELECT * FROM man", (err, result) ->
# 				result.should.eql [
# 					{id:1, name:"koen"},
# 					{id:2, name:"dirk"},
# 					{id:3, name:"hugo"}
# 				]
# 				done()
# 		
# 		it "should do select eq", (done) ->
# 			backend.execute "SELECT * FROM man WHERE id=?", [1], (err, result) ->
# 				result.should.eql [{id:1, name:"koen"}]
# 				done()
# 		
# 		it "should do select in", (done) ->
# 			backend.execute "SELECT * FROM man WHERE id IN (?, ?)", [1, 2], (err, result) ->
# 				result.should.eql [
# 					{id:1, name:"koen"},
# 					{id:2, name:"dirk"}
# 				]
# 				done()
# 		
# 		n = 10
# 		
# 		it "should do transaction", (done) ->
# 			backend.execute "BEGIN TRANSACTION", ->
# 				async.map [0..n], (value, cb) ->
# 					backend.execute "INSERT INTO man (name) VALUES (?)", value, cb
# 				, ->
# 					backend.execute "END TRANSACTION", done
# 		
# 		it "should do transaction", (done) ->
# 			async.map [0..n], (value, cb) ->
# 				backend.execute "INSERT INTO man (name) VALUES (?)", value, cb
# 			, done


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


backends = 
	sqlite: new SQLiteBackend ":memory:"
	postgres: new PostgresBackend "postgres://localhost/test"
	# mysql: new MySQLBackend {user:"root", password:"test", database:"test2"}

for backendName, backend of backends
	
	describe "Store.#{backendName}", ->
		describe "#simple", ->
		
			store = new Store backend, [models.person]

			it "should do drop", (done) ->
				store.backend.execute "DROP TABLE IF EXISTS person", done

			it "should create the store without error", (done) ->
				store.create done
		
			it "should put the data without error", (done) ->
				store.put data1, done
		
			it "should fetch the data without error", (done) ->
				store.get "person", data1.key, (err, result) ->
					data1.should.eql result
					done()
			# 
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
		
			n = 100
		
			it "should insert #{n}", (done) ->
				async.map [1..n], (c, cb) ->
					data = _.clone(data1) 
					data.key = utils.uuid()
					store.put data, cb
				, done

			it "should batch insert #{n} in transaction", (done) ->
				data = [1..n].map ->
					data = _.clone(data1) 
					data.key = utils.uuid()
					data
			
				store.put data, done

			it "should fetch a lot", (done) ->
				store.query "person", (err, result) ->
					result.length.should.equal 3+(n*2)
					done()

		
			it "should delete one", (done) ->
				store.del "person", data1.key, (err, result) ->
					store.get "person", data1.key, (err, result) ->
						should.strictEqual null, result
						done()
		
			it "should delete all", (done) ->
				store.query "person", (err, result) ->
					store.del "person", _.pluck(result, "key"), (err, result) ->
						store.query "person", (err, result) ->
							result.length.should.equal 0
							done()
