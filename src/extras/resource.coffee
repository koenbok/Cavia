log = require "winston"

# GET     /forums              ->  index	v
# GET     /forums/new          ->  new
# POST    /forums              ->  create
# GET     /forums/:forum       ->  show		v
# GET     /forums/:forum/edit  ->  edit
# PUT     /forums/:forum       ->  update	v
# DELETE  /forums/:forum       ->  destroy	v

"""
Very simple helper class to expose cavia models through express. Uses express-resource.
"""

class SQLBTResource
	
	constructor: (@store, @model, @name) ->
	
	index: (req, res) =>
		
		log.info "#{@name}.index"
		
		@store.query @model, {}, (err, result) =>
			res.send result
			res.end()

	show: (req, res) =>
		
		console.log req.params
		
		log.info "#{@name}.show\n\tkey: #{req.params[@name]}"
		
		key = req.params[@name]
		
		@store.get @model, key, (err, result) =>
			res.send result
			res.end()

	update: (req, res) =>
		
		log.info "#{@name}.update\n\tkey: #{req.params[@name]}\n\tbody: #{req.body}"

		data = JSON.parse req.body
		data.key = req.params[@name]
		data.kind = @name
		
		@store.put data, (err, result) =>
			res.send data
			res.end()

	destroy: (req, res) =>
		res.send "#{@name}.destroy " + req.params[@name]
		
exports.SQLBTResource = SQLBTResource