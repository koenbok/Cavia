async = require "async"
_ = require "underscore"
log = require "winston"

{SQLBackend} = require "./backend"
utils = require "./utils"

pg = require "pg"

class exports.PostgresBackend extends SQLBackend

	constructor: (dsl) ->
		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'

		@client = new pg.Client dsl
		@client.connect()
	
	execute: (sql, params, callback) ->
			
		if _.isFunction params
			callback = params
			params = []
		
		if params != null and not _.isArray params
			params = [params]
		
		for n in [0..params.length]
			sql = sql.replace "?", "$#{n+1}"

		# log.info "[sql] #{sql} #{inspect(params)}"
		
		cb = (err, result) ->
			throw err if err
			callback err, result.rows
			
		if sql[0..5].toLowerCase() == "select"
			@client.query sql, params, cb
		else
			@client.query sql, params, cb

	createOrUpdateRow: (table, columns, callback) ->
		
		keys = _.keys columns
		values = _.values columns

		vals = []
		
		for k, v of columns
			vals.push "#{k} = ?"

		sql = "
		WITH upsert AS
		(
			UPDATE #{table} m SET #{vals.join(', ')} WHERE m.key=?
			RETURNING m.key
		)
		INSERT INTO #{table} (#{keys.join ', '}) 
			SELECT #{utils.oinks(values)}
			WHERE NOT EXISTS (SELECT 1 FROM upsert)"
		
		params = []
		params.push.apply params, values
		params.push.apply params, [columns.key]
		params.push.apply keys, values
		params.push.apply params, values
		
		@execute sql, params, callback
