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
		timeout: 1000

	constructor: (@dsl) ->

		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'

		@client = mysql.createClient dsl
	
	_execute: (sql, params, callback) ->
		
		if sql[0..5].toLowerCase() == "select"
			@client.query sql, params, callback
		else
			@client.query sql, params, callback

	createTable: (name, callback) ->
		@execute "CREATE TABLE #{name} (#{@config.keycol} CHAR(32) NOT NULL, PRIMARY KEY (#{@config.keycol})) ENGINE = MYISAM", callback


	upsert: (table, columns, callback) ->
		
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
		
		sql = "INSERT INTO #{table} (#{keys.join ', '}) 
			VALUES (#{utils.placeholders(values)}) 
			ON DUPLICATE KEY UPDATE #{vals.join(', ')}"
		
		params = []
		params.push.apply params, values
		params.push.apply params, values
		
		@execute sql, params, callback
