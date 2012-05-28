async = require "async"
_ = require "underscore"
log = require "winston"

{SQLBackend} = require "./backend"
{inspect} = require "util"
utils = require "./utils"

sqlite3 = require "sqlite3"
sqlite3 = sqlite3.verbose() # Optional

class exports.SQLiteBackend extends SQLBackend

	constructor: (dsl) ->
		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'

		@db = new sqlite3.Database dsl
	
	_execute: (sql, params, callback) ->
			
		if sql[0..5].toLowerCase() == "select"
			@db.all sql, params, callback
		else
			@db.run sql, params, callback