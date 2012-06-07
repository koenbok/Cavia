(function() {
  var SQLBackend, async, inspect, log, sqlite3, utils, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  async = require("async");

  _ = require("underscore");

  log = require("winston");

  SQLBackend = require("./backend").SQLBackend;

  inspect = require("util").inspect;

  utils = require("./utils");

  sqlite3 = require("sqlite3");

  sqlite3 = sqlite3.verbose();

  exports.SQLiteBackend = (function(_super) {

    __extends(SQLiteBackend, _super);

    SQLiteBackend.prototype.config = {
      keycol: "key",
      valcol: "val",
      timeout: 1000
    };

    function SQLiteBackend(dsl) {
      this.typeMap = {
        string: 'VARCHAR(255)',
        text: 'TEXT',
        int: 'INT',
        float: 'FLOAT'
      };
      this.db = new sqlite3.Database(dsl);
    }

    SQLiteBackend.prototype._execute = function(sql, params, callback) {
      if (sql.slice(0, 6).toLowerCase() === "select") {
        return this.db.all(sql, params, callback);
      } else {
        return this.db.run(sql, params, callback);
      }
    };

    return SQLiteBackend;

  })(SQLBackend);

}).call(this);
