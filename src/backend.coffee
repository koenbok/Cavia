_ = require "underscore"
log = require "winston"

async = require "async"
utils = require "./utils"
{inspect} = require "util"

{SelectQuery} = require "./query"
{DeleteQuery} = require "./query"


class Backend

class exports.SQLBackend extends Backend
	
	# This is defined here because some backends need to override
	# this because they are reserved, and we need them for initial
	# table creation.
	config:
		keycol: "key"
		valcol: "value"
	
	connect: ->
	disconnect: ->

	execute: (sql, params, callback) ->
		
		if _.isFunction params
			callback = params
			params = []
		
		if @log
			log.info "[sql] #{sql} #{inspect(params)}"
		
		cb = (err, result) ->
			throw err if err
			callback(err, result)
		
		@_execute sql, params, cb

	createTable: (name, callback) ->
		@execute "CREATE TABLE #{name} (#{@config.keycol} CHAR(32) NOT NULL, PRIMARY KEY (#{@config.keycol}))", callback

	dropTable: (name, callback) ->
		@execute "DROP TABLE IF EXISTS #{name}", callback

	createColumn: (table, name, type, callback) ->
		@execute "ALTER TABLE #{table} ADD COLUMN #{name} #{@typeMap[type]}", callback
	
	dropColumn: (table, name, callback) ->
		throw "Not implemented"

	createIndex: (table, name, columns, callback) ->
		columns = columns.join ',' if _.isArray columns
		@execute "CREATE INDEX #{name} ON #{table} (#{columns})", callback

	dropIndex: (table, name, callback) ->
		# TODO
		throw "Not implemented"

	query: (query, callback) ->
		@execute query.sql, query.val, callback

	select: (table, input, callback) ->
		query = new SelectQuery table, input, {}
		@query query, callback

	delete: (table, input, callback) ->
		query = new DeleteQuery table, input, {}
		@query query, callback
	
	transaction: (callback, work) ->
		
		# All transactions get put in a single queue to execute serially,
		# while async is allowed within the transaction block. While a
		# transaction is being executed, all non transactional queries
		# are still executed.
		
		# todo: set up one transaction queue per connection?
		
		worker = (task, cb) ->
			task cb
		
		@transactionQueue ?= async.queue worker, 1
		
		steps = []
		
		steps.push (cb) => @beginTransaction cb
		steps.push work
		steps.push (cb) => @commitTransaction cb
		
		@transactionQueue.push (cb) ->
			async.series steps, cb
		
	beginTransaction: (callback) ->
		@execute "BEGIN", callback

	commitTransaction: (callback) ->
		@execute "COMMIT", callback
	
	upsert: (table, columns, callback) ->

		keys = _.keys columns
		values = _.values columns
		
		@execute "INSERT OR REPLACE INTO #{table} 
			(#{keys.join ', '}) VALUES 
			(#{utils.placeholders(values)})", 
			values, callback
