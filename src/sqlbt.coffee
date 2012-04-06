require "coffee-script"
{inspect} = require "util"

sqlite3 = require "sqlite3"
sqlite3 = sqlite3.verbose() # Optional

async = require "async"
_ = require "underscore"
log = require "winston"

utils = require "./utils"


class Backend


class SQLiteBackend extends Backend
	
	constructor: (dsl) ->
		@typeMap =
			string: 'VARCHAR(255)'
			text: 'TEXT'
			int: 'INT'
			float: 'FLOAT'

		@db = new sqlite3.Database dsl
	
	execute: (sql, params, callback) ->
			
		if _.isFunction params
			callback = params
			params = {}
		
		# log.info "[sql] #{sql} #{inspect(params)}"
		
		cb = (err, result) ->
			throw err if err
			callback(err, result)
			
		if sql[0..5].toLowerCase() == "select"
			@db.all sql, params, cb
		else
			@db.run sql, params, cb
			
	createTable: (name, callback) ->
		@execute "CREATE TABLE #{name} (key CHAR(32) NOT NULL, PRIMARY KEY (key))", callback

	createColumn: (table, name, type, callback) ->
		@execute "ALTER TABLE #{table} ADD COLUMN #{name} #{@typeMap[type]}", callback

	createIndex: (table, name, columns, callback) ->
		@execute "CREATE INDEX #{name} ON #{table} (#{columns.join ','})", callback
	
	createOrUpdateRow: (table, columns, callback) ->
		
		keys = _.keys columns
		values = _.values columns
		
		@execute "INSERT OR REPLACE INTO #{table} (#{keys.join ', '}) VALUES (#{utils.oinks(values)})", 
			values, callback
	
	fetch: (table, filters, callback) ->
		
		values = []
		sql = "SELECT * FROM #{table}"
		
		if filters is not {}

			sql += " WHERE"

			for column, filter of filters
				
				if values.length > 0
					sql += " AND"
				
				operator = filter[0]
				
				sql += " #{column} #{operator}"
				values.push filter[1]
				
				
				# operator = filter[0]
				# vals = filter[1]
				# 
				# if not _.isArray(vals)
				# 	vals = [vals]
				# 
				# values.push.apply values, vals
				# 	
				# placeholders = ["?" for i in [1..vals.length]][0]
				# 
				# 
				# sql += " #{column} #{operator} #{placeholders.join ', '}"
				
				
				# if operator == "IN"
				# 	placeholders = ["?" for i in [1..filter[1].length]][0]
				# 	sql += " #{column} #{operator} (#{placeholders.join ', '})"
				# else
				# 	sql += " #{column} #{operator} ?"
		
		@execute sql, values, callback

class Store

	constructor: (@backend, @definition) ->
		# definition is list of kind, indexes, validator, model
		
	create: (callback) ->
		
		steps = []
		
		for item in @definition
			steps.push (cb) => @createKind item.kind, cb
			steps.push (cb) =>
				
				async.map _.keys(item.indexes), (indexName, cb) =>
					index = item.indexes[indexName]
					@createIndex item.kind, index.type, indexName, cb
				, cb

		async.series steps, ->
			callback()


	createKind: (name, callback) ->
		
		columns = 
			# key: "string"
			value: "text"
		
		indexes = [["key"]]

		steps = [
			(cb) => @backend.createTable name, cb,
			(cb) => 
				async.map _.keys(columns), (column, icb) =>
					@backend.createColumn name, column, columns[column], icb
				, cb,
			(cb) =>
				async.map indexes, (columns, icb) =>
					@createIndex name, "string", columns, icb
				, cb
		]
		
		async.series steps, (error, results) ->
			callback error, results
	
	createIndex: (kind, type, name, callback) ->
		
		indexName = "#{kind}_index_#{name}"
		
		# console.log kind, type, properties, callback
		
		if type not in _.keys @backend.typeMap
			throw "Requested index type '#{type}' not supported by backend #{_.keys @backend.typeMap}"
		
		# If the property is not the object key we need to create a column
		# that can hold the indexed property so we can make an sql index on 
		# top of that.
		
		steps = []
		
		if name != "key"
			steps.push (cb) => @backend.createColumn kind, indexName, type, cb
		
		steps.push (cb) => @backend.createIndex kind, indexName, [indexName], cb
		
		async.series steps, callback
	
	put: (data, callback) ->
		
		if not _.isArray(data)
			data = [data]
		
		async.map data, (item, cb) =>
			@backend.createOrUpdateRow item.kind, @_toStore(item.kind, item), cb
		, callback
		
	
	get: (kind, key, callback) ->
		if _.isArray(key)
			@query kind, {"key": ["IN (#{utils.oinks(key)})", key]}, callback
		else
			@query kind, {"key": ["= ?", key]}, (err, result) ->
				if result.length == 1
					callback err, result[0]
				else
					callback err, null
					
	query: (kind, filters, callback) ->
		@backend.fetch kind, filters, (err, rows) =>
			callback err, rows.map (row) =>
				@_fromStore kind, row
		
		
	_toStore: (kind, data) ->

		if not data.key
			data.key = utils.uuid()
		
		key = data.key
		kind = data.kind
		
		dataCopy = _.clone data
		
		delete dataCopy.key
		delete dataCopy.kind
		
		result =
			key: data.key
			value: JSON.stringify(dataCopy)
		
		# Add the index data
		for item in @definition
			for name, index of item.indexes
				indexName = "#{kind}_index_#{name}"
				result[indexName] = index.getter(dataCopy)
		
		return result

	_fromStore: (kind, row) ->
		result = JSON.parse(row.value)
		result.key = row.key
		result.kind = kind
		return result

exports.Store = Store
exports.SQLiteBackend = SQLiteBackend