async = require "async"
_ = require "underscore"
log = require "winston"
{inspect} = require "util"

{SQLBackend} = require "./backend"
utils = require "./utils"

mysql = require "mysql"


class exports.MySQLBackend extends SQLBackend

	config:
		keycol: "keycol"
		valcol: "valcol"
		connections: 1
		timeout: 10

	constructor: (@dsl) ->
		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'

	connect: (callback) =>
		client = mysql.createClient @dsl
		callback null, client
		
	disconnect: (client) ->
		client.destroy()

	_execute: (sql, params, callback) ->
		
		@pool.acquire (err, client) =>
			client.query sql, params, (err, result) =>
				@pool.release client
				callback err, result

	createTable: (name, callback) ->
		@execute "CREATE TABLE #{name} (#{@config.keycol} CHAR(32) NOT NULL, PRIMARY KEY (#{@config.keycol})) ENGINE = MYISAM", callback

	upsert: (table, columns, callback) ->
		
		keys = _.keys columns
		values = _.values columns
		
		# http://stackoverflow.com/questions/1218905/how-do-i-update-
		# if-exists-insert-if-not-aka-upsert-or-merge-in-mysql
		
		vals = []
		
		for k, v of columns
			vals.push "#{k} = ?"
		
		sql = "INSERT INTO #{table} (#{keys.join ', '}) 
			VALUES (#{utils.placeholders(values)}) 
			ON DUPLICATE KEY UPDATE #{vals.join(', ')}"
		
		params = []
		params.push.apply params, values
		params.push.apply params, values
		
		@execute sql, params, callback
