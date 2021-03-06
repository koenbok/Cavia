{SQLiteBackend} = require "../src/backend.sqlite"
{PostgresBackend} = require "../src/backend.postgres"
{MySQLBackend} = require "../src/backend.mysql"

exports.backends = 
	sqlite: 	new SQLiteBackend ":memory:"
	postgres: 	new PostgresBackend "postgres://localhost/test"
	mysql: 		new MySQLBackend {user:"root", password:"test", database:"test2"}

# exports.backends.postgres.log = true