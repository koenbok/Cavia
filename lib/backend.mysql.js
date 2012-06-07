(function() {
  var SQLBackend, async, inspect, log, mysql, utils, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  async = require("async");

  _ = require("underscore");

  log = require("winston");

  inspect = require("util").inspect;

  SQLBackend = require("./backend").SQLBackend;

  utils = require("./utils");

  mysql = require("mysql");

  exports.MySQLBackend = (function(_super) {

    __extends(MySQLBackend, _super);

    MySQLBackend.prototype.config = {
      keycol: "keycol",
      valcol: "valcol",
      timeout: 1000
    };

    function MySQLBackend(dsl) {
      this.dsl = dsl;
      this.typeMap = {
        string: 'VARCHAR(255)',
        text: 'TEXT',
        int: 'INT',
        float: 'FLOAT'
      };
      this.client = mysql.createClient(dsl);
    }

    MySQLBackend.prototype._execute = function(sql, params, callback) {
      if (sql.slice(0, 6).toLowerCase() === "select") {
        return this.client.query(sql, params, callback);
      } else {
        return this.client.query(sql, params, callback);
      }
    };

    MySQLBackend.prototype.createTable = function(name, callback) {
      return this.execute("CREATE TABLE " + name + " (" + this.config.keycol + " CHAR(32) NOT NULL, PRIMARY KEY (" + this.config.keycol + ")) ENGINE = MYISAM", callback);
    };

    MySQLBackend.prototype.upsert = function(table, columns, callback) {
      var k, keys, params, sql, v, vals, values;
      keys = _.keys(columns);
      values = _.values(columns);
      vals = [];
      for (k in columns) {
        v = columns[k];
        vals.push("" + k + " = ?");
      }
      sql = "INSERT INTO " + table + " (" + (keys.join(', ')) + ") 			VALUES (" + (utils.placeholders(values)) + ") 			ON DUPLICATE KEY UPDATE " + (vals.join(', '));
      params = [];
      params.push.apply(params, values);
      params.push.apply(params, values);
      return this.execute(sql, params, callback);
    };

    return MySQLBackend;

  })(SQLBackend);

}).call(this);
