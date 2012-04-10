async = require "async"
_ = require "underscore"
log = require "winston"

{SQLBackend} = require "./backend"
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
	
	execute: (sql, params, callback) ->
			
		if _.isFunction params
			callback = params
			params = []
		
		# log.info "[sql] #{sql} #{inspect(params)}"
		
		cb = (err, result) ->
			throw err if err
			callback(err, result)
			
		if sql[0..5].toLowerCase() == "select"
			@db.all sql, params, cb
		else
			@db.run sql, params, cb