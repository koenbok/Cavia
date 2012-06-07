(function() {
  var MySQLBackend, PostgresBackend, SQLiteBackend, Store;

  Store = require("./store").Store;

  SQLiteBackend = require("./backend.sqlite").SQLiteBackend;

  PostgresBackend = require("./backend.postgres").PostgresBackend;

  MySQLBackend = require("./backend.mysql").MySQLBackend;

  exports.Store = Store;

  exports.backends = {
    SQLiteBackend: SQLiteBackend,
    PostgresBackend: PostgresBackend,
    MySQLBackend: MySQLBackend
  };

}).call(this);
