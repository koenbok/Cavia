fs = require "fs"
assert = require "assert"

async = require "async"
should = require "should"



utils = require "../src/utils"
_ = require "underscore"

config = require "./config"

_.map _.keys(config.backends), (backendName) ->
	backend = config.backends[backendName]
	
	describe "Backend.#{backendName}", ->
		describe "#simple", ->
			
			it "should drop a table", (done) ->
				backend.dropTable "persons", done

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
			# 
			it "should create an index on multiple col", (done) ->
				backend.createIndex "persons", "persons_index2", ["col1", "col3"], done
			
			# Data
			
			data1 = 
				col1: "Koen"
				col2: "Bok"
				col3: 10
				col4: 2.22
			
			data1[backend.config.keycol] = utils.uuid()
			
			it "should insert a row", (done) ->
				backend.upsert "persons", data1, done
			
			it "should fetch the data", (done) ->
				
				d = {}
				d["#{backend.config.keycol} ="] = data1[backend.config.keycol]
				
				backend.select "persons", d, (err, result) ->
					result.length.should.equal 1
					result[0].should.eql data1
					done()
			
			it "should update the row", (done) ->
				data1.col1 = "Koentje"
				backend.upsert "persons", data1, done
			
			it "should fetch the updated data", (done) ->
				
				d = {}
				d["#{backend.config.keycol} ="] = data1[backend.config.keycol]
				
				backend.select "persons", d, (err, result) ->
					result.length.should.equal 1
					result[0].should.eql data1
					done()
			
			# it "should disconnect", (done) ->
			# 	backend.disconnect()
			# 	done()
