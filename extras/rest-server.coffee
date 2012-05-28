require "coffee-script"


util = require "util"
express = require "express"
resource = require "express-resource"
sqlbtjs = require "./sqlbtjs/src/index"

app = express.createServer()
app.use express.bodyParser()

CONFIG =
	dsn: "postgres://localhost/test"
	port: 8000

MODELS = 
	person:
		kind: "person"
		indexes:
			name: {type: "string", getter: (o) -> o.name}
			age: {type: "int", getter: (o) -> o.age}

backend = new sqlbtjs.backends.PostgresBackend CONFIG.dsn
store = new sqlbtjs.Store backend, [MODELS.person]

class SQLBTResource
	
	constructor: (@name) ->
	
	index: (req, res) =>
		store.get @name, {}, (err, result) =>
			res.send result

	create: (req, res) =>
		res.send "#{@name}.create" + util.inspect(req) + req.body.objectData

	show: (req, res) =>
		store.get @name, req.params[@name], (err, result) =>
			res.send result
		
		# res.send "#{@name}.show " + req.params[@name]

	edit: (req, res) =>
		res.send "#{@name}.edit " + req.params[@name]

	update: (req, res) =>
		res.send "#{@name}.update " + req.params[@name]

	destroy: (req, res) =>
		res.send "#{@name}.destroy " + req.params[@name]

app.resource "persons", new SQLBTResource "person"


http = require "http"

app.listen CONFIG.port, ->
	console.log "Listening on #{CONFIG.port}"

	http.post { host: 'localhost', port: CONFIG.port, path: "/persons"}, "TEST", (res) ->
		data = ''
		res.on 'data', (chunk) ->
			data += chunk.toString()
		res.on 'end', () ->
			console.log data
	