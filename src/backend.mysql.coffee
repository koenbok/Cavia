async = require "async"
_ = require "underscore"
log = require "winston"
{inspect} = require "util"

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
			if sql[0..5].toLowerCase() not in ["create"]
				@client.query "USE #{@dsl.database}", =>
					@_usedb = true
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
			callback err, result
			
		if sql[0..5].toLowerCase() == "select"
			@client.query sql, params, cb
		else
			@client.query sql, params, cb

	createOrUpdateRow: (table, columns, callback) ->
		
		keys = _.keys columns
		values = _.values columns
		
		# http://stackoverflow.com/questions/1218905/how-do-i-update-if-exists-insert-if-not-aka-upsert-or-merge-in-mysql
		# INSERT INTO `usage`
		# 	(`thing_id`, `times_used`, `first_time_used`)
		# 	VALUES
		# 	(4815162342, 1, NOW())
		# 	ON DUPLICATE KEY UPDATE
		# 	`times_used` = `times_used` + 1
		
		vals = []
		
		for k, v of columns
			vals.push "#{k} = ?"
		
		sql = "INSERT INTO #{table} (#{keys.join ', '}) VALUES (#{utils.oinks(values)}) 
			ON DUPLICATE KEY UPDATE #{vals.join(', ')}"
		
		params = []
		params.push.apply params, values
		params.push.apply params, values
		
		@execute sql, params, callback
