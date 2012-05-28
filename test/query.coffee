fs = require "fs"
assert = require "assert"

async = require "async"
should = require "should"

{SelectQuery} = require "../src/query"
{DeleteQuery} = require "../src/query"

# WHERE key = ? 
# WHERE key IN (?,?,?)
# WHERE key > ? AND val = ?

# {"key =": val}
# {"key IN": [a, b, c]}
# {"key >": 12, }

describe "Query", ->
	describe "#sql", ->

		it "should create the right sql", (done) ->
			
			q = new SelectQuery "persons", {}
			q.sql.should.equal "SELECT * FROM persons"
			q.val.should.eql []

			q = new SelectQuery "persons", {}, columns: ["key"]
			q.sql.should.equal "SELECT key FROM persons"
			q.val.should.eql []

			q = new SelectQuery "persons", {}, columns: ["key", "value"]
			q.sql.should.equal "SELECT key,value FROM persons"
			q.val.should.eql []

			q = new SelectQuery "persons", {"key =": "abc"}
			q.sql.should.equal "SELECT * FROM persons WHERE key = ?"
			q.val.should.eql ["abc"]
			
			q = new SelectQuery "persons", {"key IN": ["abc"]}
			q.sql.should.equal "SELECT * FROM persons WHERE key IN (?)"
			q.val.should.eql ["abc"]
			
			q = new SelectQuery "persons", {"key >": 123}
			q.sql.should.equal "SELECT * FROM persons WHERE key > ?"
			q.val.should.eql [123]
			
			q = new SelectQuery "persons", {"key >": 5, "key <": 10}
			q.sql.should.equal "SELECT * FROM persons WHERE key > ? AND key < ?"
			q.val.should.eql [5, 10]
			
			subquery = new SelectQuery "persons_name_index_table", 
				{"value =": "koen"}, 
				{columns: ["key"]}
			
			topquery = new SelectQuery "persons", 
				{"key IN": subquery}

			topquery.sql.should.equal "SELECT * FROM persons WHERE key IN (SELECT key FROM persons_name_index_table WHERE value = ?)"
			topquery.val.should.eql ["koen"]
			
			done()
