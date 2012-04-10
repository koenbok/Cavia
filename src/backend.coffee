async = require "async"
_ = require "underscore"
log = require "winston"

utils = require "./utils"

class Backend


class exports.SQLBackend extends Backend
			
	createTable: (name, callback) ->
		@execute "CREATE TABLE #{name} (keycol CHAR(32) NOT NULL, PRIMARY KEY (keycol))", callback

	dropTable: (name, callback) ->
		@execute "DROP TABLE IF EXISTS #{name}", callback

	createColumn: (table, name, type, callback) ->
		@execute "ALTER TABLE #{table} ADD COLUMN #{name} #{@typeMap[type]}", callback

	createIndex: (table, name, columns, callback) ->
		@execute "CREATE INDEX #{name} ON #{table} (#{columns.join ','})", callback

	
	createOrUpdateRow: (table, columns, callback) ->
		
		keys = _.keys columns
		values = _.values columns
		
		@execute "INSERT OR REPLACE INTO #{table} (#{keys.join ', '}) VALUES (#{utils.oinks(values)})", 
			values, callback
	
	createOrUpdateRows: (table, rows, callback) ->
		
		if rows.length == 1
			@createOrUpdateRow table, rows[0], callback
			return
		
		steps = [
			(cb) => @execute "BEGIN", cb
			(cb) => 
				async.map rows, (columns, icb) =>
					@createOrUpdateRow table, columns, icb
				, cb
			(cb) => @execute "COMMIT", cb
		]
		
		async.series steps, callback
	
	filter: (filters) ->
		
		if filters != {}
			return ["", []]
		
		val = []
		sql = [" WHERE"]

		for column, filter of filters
			sql.push " AND" if val.length > 0
			sql.push " #{column} #{filter[0]}"
			val.push filter[1]
		
		return [sql.join(""), val]
	
	fetch: (table, filters, callback) ->
		res = @filter(filters)
		@execute "SELECT * FROM #{table}#{res[0]}", res[1], callback

	delete: (table, filters, callback) ->
		res = @filter(filters)
		@execute "DELETE FROM #{table}#{res[0]}", res[1], callback
