_ = require "underscore"
utils = require "./utils"


# WHERE key = ? 
# WHERE key IN (?,?,?)
# WHERE key > ? AND val = ?

# {"key =": val}
# {"key IN": [a, b, c]}
# {"key >": 12, }



class Query
	
	constructor: (@table, @input, @options) ->
		
		@options ?= {}
		@placeholder = @options.placeholder? or "?"
		
		result = []
		values = []
		
		if @options.columns
			result.push "SELECT #{@options.columns.join ","} FROM #{table}"
		else
			result.push "SELECT * FROM #{table}"
			
		for key, value of @input
		
			key = key.split " "
			
			column   = key[0]
			operator = key[1]
			
			if !column or !operator
				throw new Error "Invalid query key: #{key}"
			
			operator = operator.toUpperCase()
					
			if result.length is 1
				result.push " WHERE "
			else
				result.push " AND "
			
			if operator in ["=", ">", "<", ">=", "=<"]
				result.push "#{column} #{operator} #{@placeholder}"
				values.push value
			
			else if operator is "IN"
				
				if _.isArray value
					result.push "#{column} IN (#{utils.placeholders(value, @placeholder)})"
					values.push v for v in value
						
				# Check if query object and build a subquery
				else if value.sql and value.val
					result.push "#{column} IN (#{value.sql})"
					values.push v for v in value.val
					
				else
					throw new Error "IN operator requires list of values or subquery"
					
			else
				throw new Error "Invalid operator: #{operator}"


		@sql = result.join ""
		@val = values

class exports.SelectQuery extends Query
	type = "select"

class exports.DeleteQuery extends Query
	type = "delete"