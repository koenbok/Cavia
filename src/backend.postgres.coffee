async = require "async"
_ = require "underscore"
log = require "winston"

{SQLBackend} = require "./backend"
utils = require "./utils"
util = require "util"

pg = require "pg"

class exports.PostgresBackend extends SQLBackend

	config:
		keycol: "key"
		valcol: "val"
		timeout: 1000

	constructor: (dsl, @options) ->

		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'
		
		@client = new pg.Client dsl
	
	_connect: ->
		@client.connect()
	
	_disconnect: ->
		@client.end()

	_execute: (sql, params, callback) ->
		
		for n in [0..params.length]
			sql = sql.replace "?", "$#{n+1}"
		
		cb = (err, result) ->
			callback err, result.rows
		
		if sql[0..5].toLowerCase() == "select"
			@client.query sql, params, cb
		else
			@client.query sql, params, cb

	upsert: (table, columns, callback) ->
		
		keys = _.keys columns
		values = _.values columns

		vals = []
		
		for k, v of columns
			vals.push "#{k} = ?"
		
		sql = "
		WITH upsert AS
		(
			UPDATE #{table} m SET #{vals.join(', ')} WHERE m.#{@config.keycol}=?
			RETURNING m.#{@config.keycol}
		)
		INSERT INTO #{table} (#{keys.join ', '}) 
			SELECT #{utils.placeholders(values)}
			WHERE NOT EXISTS (SELECT 1 FROM upsert)"
		
		key = columns[@config.keycol]
		params = []
		
		params.push.apply params, values
		params.push.apply params, [key]
		params.push.apply keys, values
		params.push.apply params, values

		@execute sql, params, callback
