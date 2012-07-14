require "coffee-script"

util = 		require "util"
log = 		require "winston"
express = 	require "express"
Resource = 	require "express-resource"
{gzip} =	require "connect-gzip"

sqlbtjs =	require "../../src"
{SQLBTResource} = require "../../src/extras/resource"


# Configuration
config =
	dsn: process.env.DATABASE_URL or "postgres://localhost/test"
	port: process.env.PORT or 5000
	backend:
		log: true
		timeout: 60 * 10


# Define some models with indexes
models = 
	person:
		indexes:
			name: 	["string", (data) -> data.name]
			age: 	["int", (data) -> data.age]
	product:
		indexes:
			name: 	["string", (data) -> data.name]
			price: 	["int", (data) -> data.price]


# Set up the backend and connect the resources

backend = new sqlbtjs.backends.SQLiteBackend "/tmp/test.sqlite3"
# backend = new sqlbtjs.backends.PostgresBackend config.dsn
store = new sqlbtjs.Store backend, models

backend.log = config.backend.log
backend.config.timeout = config.backend.timeout


# Build the server
app = express.createServer()
app.use express.bodyParser()
app.use gzip()

app.resource "api/persons", new SQLBTResource store, "person", "person"
app.resource "api/products", new SQLBTResource store, "product", "product"

store.create ->
	app.listen config.port, ->
		log.info "Listening on #{config.port}"
