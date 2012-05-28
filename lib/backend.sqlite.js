(function() {
  var SQLBackend, async, log, sqlite3, utils, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  async = require("async");

  _ = require("underscore");

  log = require("winston");

  SQLBackend = require("./backend").SQLBackend;

  utils = require("./utils");

  sqlite3 = require("sqlite3");

  sqlite3 = sqlite3.verbose();

  exports.SQLiteBackend = (function(_super) {

    __extends(SQLiteBackend, _super);

    function SQLiteBackend(dsl) {
      this.typeMap = {
        string: 'VARCHAR(255)',
        text: 'TEXT',
        int: 'INT',
        float: 'FLOAT'
      };
      this.db = new sqlite3.Database(dsl);
    }

    SQLiteBackend.prototype.execute = function(sql, params, callback) {
      var cb;
      if (_.isFunction(params)) {
        callback = params;
        params = [];
      }
      cb = function(err, result) {
        if (err) throw err;
        return callback(err, result);
      };
      if (sql.slice(0, 6).toLowerCase() === "select") {
        return this.db.all(sql, params, cb);
      } else {
        return this.db.run(sql, params, cb);
      }
    };

    return SQLiteBackend;

  })(SQLBackend);

}).call(this);
