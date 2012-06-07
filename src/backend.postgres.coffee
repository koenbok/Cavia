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
		connections: 1
		timeout: 10

	constructor: (@dsn, @options) ->

		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'
	
	connect: (callback) =>
		client = new pg.Client @dsn
		client.connect()
		
		client.on "connect", ->
			callback null, client
		client.on "error", (err) ->
			callback err
		
	disconnect: (client) ->
		client.end()
		
	_execute: (sql, params, callback) ->
		
		for n in [0..params.length]
			sql = sql.replace "?", "$#{n+1}"
		
		cb = (err, result) ->
			if result
				callback err, result.rows
			else
				callback err
		
		@pool.acquire (err, client) =>
			client.query sql, params, (err, result) =>
				@pool.release client
				cb err, result


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
