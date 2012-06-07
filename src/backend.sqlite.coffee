async = require "async"
_ = require "underscore"
log = require "winston"

{SQLBackend} = require "./backend"
{inspect} = require "util"
utils = require "./utils"

sqlite3 = require "sqlite3"
sqlite3 = sqlite3.verbose() # Optional

class exports.SQLiteBackend extends SQLBackend

	config:
		keycol: "key"
		valcol: "val"
		connections: 1
		timeout: 10

	constructor: (@dsl) ->

		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'

		@db = new sqlite3.Database @dsl

	connect: (callback) =>
		# client = new sqlite3.Database @dsl
		# callback null, client

	disconnect: (client) ->
		# client.close()

	_execute: (sql, params, callback) ->
		
		if sql[0..5].toLowerCase() == "select"
			@db.all sql, params, callback
		else
			@db.run sql, params, callback
		
		# For sqlite, it's probarbly not a good idea to use a pool
		
		# @pool.acquire (err, client) =>
		# 	if sql[0..5].toLowerCase() == "select"
		# 		client.all sql, params, (err, result) =>
		# 			@pool.release client
		# 			callback err, result
		# 	else
		# 		client.run sql, params, (err, result) =>
		# 			@pool.release client
		# 			callback err, result
