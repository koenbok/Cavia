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

backends = 
	sqlite: new SQLiteBackend ":memory:"
	# postgres: new PostgresBackend "postgres://localhost/test"
	# mysql: new MySQLBackend {user:"root", password:"test", database:"test2"}


			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'

for backendName, backend of backends
	
	describe "Backend.#{backendName}", ->
		describe "#simple", ->

			it "should create a table", (done) ->
				backend.createTable "persons", done
			
			# Columns
			
			it "should add a string collumn", (done) ->
				backend.createColumn "persons", "col1", "string", done

			it "should add a text collumn", (done) ->
				backend.createColumn "persons", "col2", "text", done

			it "should add an int collumn", (done) ->
				backend.createColumn "persons", "col3", "int", done

			it "should add a float collumn", (done) ->
				backend.createColumn "persons", "col4", "float", done

			# it "should drop a collumn", (done) ->
			# 	backend.createColumn "persons", "col1", "string", done
			
			# Indexes
			
			it "should create an index on a single col", (done) ->
				backend.createIndex "persons", "persons_index1", "col1", done

			it "should create an index on multiple col", (done) ->
				backend.createIndex "persons", "persons_index2", ["col1", "col2"], done

			# Data
			
			data1 = 
				key: utils.uuid()
				col1: "Koen"
				col2: "Bok"
				col3: 10
				col4: 2.22
			
			it "should insert a row", (done) ->
				backend.upsert "persons", data1, done
			
			it "should fetch the data", (done) ->
				backend.select "persons", {"key =": data1.key}, (err, result) ->
					result.length.should.equal 1
					result[0].should.eql data1
					done()

			it "should update the row", (done) ->
				data1.col1 = "Koentje"
				backend.upsert "persons", data1, done
			
			it "should fetch the data", (done) ->
				backend.select "persons", {"key =": data1.key}, done
