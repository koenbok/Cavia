require "coffee-script"
{inspect} = require "util"

async = require "async"
_ = require "underscore"
log = require "winston"

utils = require "./utils"

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
		
		# indexes = [["key"]]
		# custom index is not needed: http://stackoverflow.com/questions/3379292/is-an-index-needed-for-a-primary-key-in-sqlite
		indexes = []

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
		
		# async.map data, (item, cb) =>
		# 	@backend.createOrUpdateRow item.kind, @_toStore(item.kind, item), cb
		# , callback
		
		kind = null
		putd = []
		
		for item in data
			
			if not kind
				kind = item.kind
			else
				if not kind == item.kind
					throw "Put should all be same kind"
			
			putd.push @_toStore kind, item
		
		@backend.createOrUpdateRows kind, putd, callback
		
	
	get: (kind, key, callback) ->
		if _.isArray(key)
			@query kind, {"key": ["IN (#{utils.oinks(key)})", key]}, callback
		else
			@query kind, {"key": ["= ?", key]}, (err, result) ->
				if result.length == 1
					callback err, result[0]
				else
					callback err, null

	del: (kind, key, callback) ->
		if _.isArray(key)
			@backend.delete kind, {"key": ["IN (#{utils.oinks(key)})", key]}, callback
		else
			@backend.delete kind, {"key": ["= ?", key]}, callback
					
	query: (kind, filters, callback) ->
		if not callback and _.isFunction(filters)
			callback = filters
			filters = {}
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