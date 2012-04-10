async = require "async"
_ = require "underscore"
log = require "winston"

{SQLBackend} = require "./backend"
utils = require "./utils"

mysql = require "mysql"


class exports.MySQLBackend extends SQLBackend

	constructor: (@dsl) ->
		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'
		
		@_usedb = false
		
		@client = mysql.createClient dsl
	
	execute: (sql, params, callback) ->
		
		# Check if we already selected the database for use
		if not @_usedb
			if sql[0..5].toLowerCase() != "create"
				@client.query "USE #{@dsl.database}", =>
					@execute sql, params, callback
					return
		
		if _.isFunction params
			callback = params
			params = []
		
		if params != null and not _.isArray params
			params = [params]

		# log.info "[sql] #{sql} #{inspect(params)}"
		
		cb = (err, result) ->
			throw err if err
			callback err, result.rows
			
		if sql[0..5].toLowerCase() == "select"
			@client.query sql, params, cb
		else
			@client.query sql, params, cb
