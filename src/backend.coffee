_ = require "underscore"
log = require "winston"

async = require "async"
utils = require "./utils"
{inspect} = require "util"

{SelectQuery} = require "./query"
{DeleteQuery} = require "./query"

pooling = require "generic-pool"

class Backend

class exports.SQLBackend extends Backend

	setupPool: ->
		@pool = pooling.Pool
			name: "store"
			create: @connect
			destroy: @disconnect
			max: @config.connections # Setting this > 1 breaks transactions
			idleTimeoutMillis: @config.timeout * 1000
			log: false
	
	execute: (sql, params, callback) ->
		
		@setupPool() if not @pool
		
		if _.isFunction params
			callback = params
			params = []
		
		if @log
			
			@_logCounter ?= 0
			@_logCounter += 1
			
			log.debug "sql:#{@_logCounter}", "#{sql.replace `/\t/g`,''} #{inspect(params)}"
		
		cb = (err, result) =>
			log.error err if err
			callback(err, result)
		
		@_execute sql, params, cb

	createTable: (name, options, callback) ->
		
		callback ?= options
		
		if options.pk is false
			@execute "CREATE TABLE #{name} (#{@config.keycol} CHAR(32) NOT NULL)", callback
		else
			@execute "CREATE TABLE #{name} (#{@config.keycol} CHAR(32) NOT NULL, PRIMARY KEY (#{@config.keycol}))", callback

	dropTable: (name, callback) ->
		@execute "DROP TABLE IF EXISTS #{name}", callback

	createColumn: (table, name, type, callback) ->
		@execute "ALTER TABLE #{table} ADD COLUMN #{name} #{@typeMap[type]}", callback
	
	dropColumn: (table, name, callback) ->
		throw new Error "Not implemented"

	createIndex: (table, name, columns, callback) ->
		columns = columns.join ',' if _.isArray columns
		@execute "CREATE INDEX #{name} ON #{table} (#{columns})", callback

	dropIndex: (table, name, callback) ->
		# TODO
		throw new Error "Not implemented"
		
	query: (query, callback) ->
		@execute query.sql, query.val, callback
	
	select: (table, input, callback) ->
		query = new SelectQuery table, input, {}
		@query query, callback

	delete: (table, input, callback) ->
		query = new DeleteQuery table, input, {}
		@query query, callback
	
	transaction: (work, callback) ->
		
		# All transactions get put in a single queue to execute serially,
		# async is allowed within the transaction block. While a
		# transaction is being executed, all non transactional queries
		# (like selects) are still executed.
		
		# todo: set up one transaction queue per connection?
		
		worker = (task, cb) ->
			task cb
		
		@transactionQueue ?= async.queue worker, 1
		
		steps = []
		
		steps.push (cb) => @beginTransaction cb
		steps.push work
		steps.push (cb) => @commitTransaction cb
		
		@transactionQueue.push (cb) ->
			async.series steps, (result) ->
				cb() # Start the next transaction
				callback(result) # Let the callee know we're done
		
		# async.series steps, callback
		
	beginTransaction: (callback) ->
		@execute "BEGIN", callback

	commitTransaction: (callback) ->
		@execute "COMMIT", callback
	
	insert: (table, columns, callback) ->

		keys = _.keys columns
		values = _.values columns
		
		@execute "INSERT INTO #{table} 
			(#{keys.join ', '}) VALUES 
			(#{utils.placeholders(values)})", 
			values, callback
	
	upsert: (table, columns, callback) ->

		keys = _.keys columns
		values = _.values columns
		
		@execute "INSERT OR REPLACE INTO #{table} 
			(#{keys.join ', '}) VALUES 
			(#{utils.placeholders(values)})", 
			values, callback
