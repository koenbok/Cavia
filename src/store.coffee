require "coffee-script"
{inspect} = require "util"

async = require "async"
_ = require "underscore"
log = require "winston"

{SelectQuery} = require "./query"
{DeleteQuery} = require "./query"
utils = require "./utils"

class Store

	constructor: (@backend, @definition) ->
		# definition is list of kind, indexes, validator, model

	create: (callback) ->
		
		steps = []
		
		for kindName, kind of @definition
			
			steps.push (cb) =>
				@createKind kindName, cb
			
			steps.push (cb) =>
				async.map _.keys(kind.indexes), (indexName, icb) =>
					index = kind.indexes[indexName]
					@createIndex kindName, index[0], indexName, icb
				, cb
		
		async.series steps, callback
	
	destroy: (callback) ->
		
		steps = []
		
		for kindName, kind of @definition
			
			steps.push (cb) =>
				@destroyKind kindName, cb
			
			steps.push (cb) =>
				async.map _.keys(kind.indexes), (indexName, cb) =>
					@destroyIndex kindName, indexName, cb
				, cb
		
		async.series steps, callback
	
	destroyKind: (name, callback) ->
		@backend.dropTable name, callback
		
	createKind: (name, callback) ->
		
		columns = 
			value: "text"

		steps = []
		
		steps.push (cb) => 
			@backend.createTable name, cb
		steps.push (cb) => 
			async.map _.keys(columns), (column, cb) =>
				@backend.createColumn name, column, columns[column], cb
			, cb
		
		async.series steps, callback
	
	destroyIndex: (kind, name, callback) ->
		indexTableName = "#{kind}_index_#{name}_table"
		@backend.dropTable indexTableName, callback
		
	createIndex: (kind, type, name, callback) ->

		indexTableName = "#{kind}_index_#{name}_table"
		indexName = "#{kind}_index_#{name}"
		
		if type not in _.keys @backend.typeMap
			throw "Requested index type '#{type}' not supported by backend #{_.keys @backend.typeMap}"
		
		steps = []
		
		steps.push (cb) => @backend.createTable indexTableName, cb
		steps.push (cb) => @backend.createColumn indexTableName, "value", type, cb
				
		async.series steps, callback
	
	put: (data, callback) ->
		
		if not _.isArray data
			data = [data]

		transactionSteps = []
		
		transactionSteps.push (cb) =>
			@backend.beginTransaction cb

		transactionSteps.push (cb) => 
			async.map data, (item, cb) =>
				
				steps = []
				
				# Update the values in the kind table
				steps.push (cb) =>
					@backend.upsert item.kind, @_toStore(item.kind, item), cb
				
				# Update all index tables with fresh data
				indexes = @definition[item.kind].indexes
				
				_.keys(indexes).map (indexName) =>
					
					index = indexes[indexName]
					indexTableName = "#{item.kind}_index_#{indexName}_table"
					
					steps.push (cb) =>
						
						indexData = {}
						indexData[@backend.config.keycol] = item.key
						indexData["value"] = index[1](item)
						
						@backend.upsert indexTableName, indexData, cb
				
				# Insert all the data in parallel
				async.parallel steps, cb
				
			, cb
			
		transactionSteps.push (cb) =>
			@backend.commitTransaction cb
		
		async.series transactionSteps, callback

	get: (kind, keys, callback) ->
		
		if not _.isArray(keys)
			keys = [keys]
		
		key = "#{@backend.config.keycol} IN"
		query = new SelectQuery kind, {key: keys}
		
		@backend.query query, callback
		# 
		# 	@query kind, {"keycol": ["IN (#{utils.oinks(key)})", key]}, callback
		# else
		# 	@query kind, {"keycol": ["= ?", key]}, (err, result) ->
		# 		if result.length == 1
		# 			callback err, result[0]
		# 		else
		# 			callback err, null

	# del: (kind, key, callback) ->
	# 	if _.isArray(key)
	# 		@backend.delete kind, {"keycol": ["IN (#{utils.oinks(key)})", key]}, callback
	# 	else
	# 		@backend.delete kind, {"keycol": ["= ?", key]}, callback
					
	# query: (kind, filters, callback) ->
	# 	if not callback and _.isFunction(filters)
	# 		callback = filters
	# 		filters = {}
	# 	
	# 	@backend.fetch kind, filters, (err, rows) =>
	# 		
	# 		rows2 = rows.map (row) =>
	# 			@_fromStore kind, row
	# 		
	# 		callback err, rows2
		
		
	_toStore: (kind, data) ->

		if not data.key
			data.key = utils.uuid()
		
		key = data.key
		kind = data.kind
		
		dataCopy = _.clone data
		
		delete dataCopy[@backend.config.keycol]
		delete dataCopy.kind
		
		result = {}
		result[@backend.config.keycol] = data.key
		result["value"] = @_serialize(dataCopy)
		
		return result

	_fromStore: (kind, row) ->
		result = @_deserialize(row.value)
		result.key = row[backend.config.keycol]
		result.kind = kind
		return result
	
	_serialize: (data) ->
		JSON.stringify(data)
	
	_deserialize: (str) ->
		JSON.parse(str)

exports.Store = Store