require "coffee-script"
{inspect} = require "util"

async = require "async"
_ = require "underscore"
log = require "winston"

{SelectQuery} = require "./query"
{DeleteQuery} = require "./query"
utils = require "./utils"

ignoreError = utils.ignoreError

class Store

	constructor: (@backend, @definition) ->
		# definition is list of kind, indexes, validator, model
	
	create: (callback) ->
		
		steps = []
		
		_.map _.keys(@definition), (kindName) =>
			kind = @definition[kindName]
			steps.push (cb) => @createKind kindName, ignoreError(cb)
			
			_.map _.keys(kind.indexes), (indexName) =>
				index = kind.indexes[indexName]
				steps.push (cb) => @createIndex kindName, index[0], indexName, ignoreError(cb)

		async.series steps, callback
	
	destroy: (callback) ->
		
		steps = []
		
		_.map _.keys(@definition), (kindName) =>
			kind = @definition[kindName]
			steps.push (cb) => @destroyKind kindName, cb
			
			_.map _.keys(kind.indexes), (indexName) =>
				index = kind.indexes[indexName]
				steps.push (cb) => @destroyIndex kindName, indexName, cb
		
		async.series steps, callback
	
	_checkForKind: (kind) ->
		# See if the kind is actually defined
		if not @definition[kind]
			throw new Error "No definition for kind: #{kind}"
	
	_isListIndex: (type) ->
		# See if we're dealing with a list index. List
		# indexes are prefixed with list:<type>. We can just
		return type[0..4] == "list:"
	
	createKind: (name, callback) ->
		
		columns = 
			value: "text"

		steps = []
		
		steps.push (cb) => 
			@backend.createTable name, cb
		
		_.map _.keys(columns), (columnName, cb) =>
			steps.push (cb) => 
				column = columns[columnName]
				@backend.createColumn name, columnName, column, cb
		
		async.series steps, callback

	destroyKind: (name, callback) ->
		@backend.dropTable name, callback
		
	createIndex: (kind, type, name, callback) ->

		indexTableName = "#{kind}_index_#{name}_table"
		indexKeyName = "#{kind}_index_#{@backend.config.keycol}"
		indexValName = "#{kind}_index_#{name}"
		
		# See if we're creating a list index. List
		# indexes are prefixed with list:<type>. We can just
		# use the type here, we only need to know it's a list
		# when we modify the index.
		if @_isListIndex type
			type = type[5..]
		
		if type not in _.keys @backend.typeMap
			throw Error "Index type '#{type}' not supported by backend #{_.keys @backend.typeMap}"
		
		steps = []
		
		# For indexes we create a table without a primary key. The reason is that lists
		# need to insert multiple entries for they key. Because we need to look up index
		# entries by key fast for deletion, we add an index too.
		steps.push (cb) => @backend.createTable indexTableName, pk:false, cb
		steps.push (cb) => @backend.createColumn indexTableName, "value", type, cb
		steps.push (cb) => @backend.createIndex indexTableName, indexValName, "value", cb
		steps.push (cb) => @backend.createIndex indexTableName, indexKeyName, @backend.config.keycol, cb
		
		async.series steps, callback

	destroyIndex: (kind, name, callback) ->
		indexTableName = "#{kind}_index_#{name}_table"
		@backend.dropTable indexTableName, callback

	get: (kind, keys, callback) ->
		
		@_checkForKind(kind)
		
		if not _.isArray keys
			keys = [keys]
			single = true
		
		# Hmmm this is not ideal
		d = {}
		d[@backend.config.keycol + " IN"] = keys
		
		query = new SelectQuery kind, d
		
		@backend.query query, (err, results) =>

			if single
				if results[0]
					callback err, @_fromStore(kind, results[0])
				else
					callback err, null
				
			else
				# Map the result order to the key order, that is appearently
				# not how sql queries work, and it actually makes sense.
				
				resultMap = {}
				resultMapped = []
				
				for item in results
					resultData = @_fromStore kind, item
					resultMap[resultData.key] = resultData
				
				for key in keys
					resultMapped.push resultMap[key]
			
				callback err, resultMapped

	put: (data, callback) ->

		if not _.isArray data
			data = [data]
		
		steps = _.map data, (item) =>
			
			@_checkForKind(item.kind)
			
			itemSteps = []
			
			# Update the master table with the new values
			itemSteps.push (cb) =>
				@backend.upsert item.kind, @_toStore(item.kind, item), cb
			
			# Update all index tables with fresh data
			
			indexes = @definition[item.kind].indexes
			
			_.keys(indexes).map (indexName) =>
				
				index = indexes[indexName]
				indexType = index[0]
				indexFunction = index[1]
				indexTableName = "#{item.kind}_index_#{indexName}_table"
				
				# If this is a list index, we have multiple index entries,
				# so we need to sync these to the new set. The simplest strategy
				# is to delete and create all entries again.
				if @_isListIndex indexType
					
					indexValues = indexFunction(item)
					
					# We should get an array value for a list. Let's be a little strict here.
					if not _.isArray indexValues
						throw Error "List index requires array value: #{indexValues}"
					
					# Remove all previous index data so we end up with a correct set
					itemSteps.push (cb) =>
						
						d = {}
						d[@backend.config.keycol + " ="] = item.key
						
						@backend.delete indexTableName, d, cb
				
				else
					indexValues = [indexFunction(item)]
				
				_(indexValues).map (indexValue) =>
					
					keyColumn = @backend.config.keycol
					valColumn = "value"
					
					indexData = {}
					indexData[keyColumn] = item.key
					indexData[valColumn] = indexValue
					
					itemSteps.push (cb) =>
						@backend.insert indexTableName, indexData, cb
				
			(cb) => async.series itemSteps, cb
		
		transactionWork = (cb) =>
			async.parallel steps, cb
		
		@backend.transaction transactionWork, callback
		
		# Without a transaction
		# transactionWork callback


	query: (kind, filter, options, callback) ->
		
		callback ?= options # Allow to skip options
		callback ?= filter # Allow to skip filter for all
		
		@_checkForKind(kind)
		
		# For empty filters we can fetch the results straight from
		# the main table without using any indexes.
		if not filter or not _.keys(filter).length
			@backend.select kind, {}, (err, results) =>
				callback err, _.map results, (item) =>
					@_fromStore kind, item
		
		for key, value of filter

			filter = key.split " "
			
			column   = filter[0]
			operator = filter[1]
			
			indexTableName = "#{kind}_index_#{column}_table"

			# We only allow querying on existing indexes
			if column not in _.keys @definition[kind].indexes
				throw new Error "No index for #{kind}.#{column}"
			
			d = {}
			d["value #{operator}"] = value
			
			subquery = new SelectQuery indexTableName, 
				d, 
				{columns:[@backend.config.keycol], distinct:true}
			
			d = {}
			d["#{@backend.config.keycol} IN"] = subquery
			
			topquery = new SelectQuery kind, d
			
			@backend.query topquery, (err, results) =>
				callback err, _.map results, (item) =>
					@_fromStore kind, item
			
			# We only support one index per query for now
			return	
		
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
		result.key = row[@backend.config.keycol]
		result.kind = kind
		return result
	
	_serialize: (data) ->
		JSON.stringify(data)
	
	_deserialize: (str) ->
		JSON.parse(str)

exports.Store = Store