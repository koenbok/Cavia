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

    function MySQLBackend(dsl) {
      this.dsl = dsl;
      this.typeMap = {
        string: 'VARCHAR(255)',
        text: 'TEXT',
        int: 'INT',
        float: 'FLOAT'
      };
      this._usedb = false;
      this.client = mysql.createClient(dsl);
    }

    MySQLBackend.prototype.execute = function(sql, params, callback) {
      var cb, _ref,
        _this = this;
      if (!this._usedb) {
        if ((_ref = sql.slice(0, 6).toLowerCase()) !== "create") {
          this.client.query("USE " + this.dsl.database, function() {
            _this._usedb = true;
            _this.execute(sql, params, callback);
          });
        }
      }
      if (_.isFunction(params)) {
        callback = params;
        params = [];
      }
      if (params !== null && !_.isArray(params)) params = [params];
      cb = function(err, result) {
        if (err) throw err;
        return callback(err, result);
      };
      if (sql.slice(0, 6).toLowerCase() === "select") {
        return this.client.query(sql, params, cb);
      } else {
        return this.client.query(sql, params, cb);
      }
    };

    MySQLBackend.prototype.createOrUpdateRow = function(table, columns, callback) {
      var k, keys, params, sql, v, vals, values;
      keys = _.keys(columns);
      values = _.values(columns);
      vals = [];
      for (k in columns) {
        v = columns[k];
        vals.push("" + k + " = ?");
      }
      sql = "INSERT INTO " + table + " (" + (keys.join(', ')) + ") VALUES (" + (utils.oinks(values)) + ") 			ON DUPLICATE KEY UPDATE " + (vals.join(', '));
      params = [];
      params.push.apply(params, values);
      params.push.apply(params, values);
      return this.execute(sql, params, callback);
    };

    return MySQLBackend;

  })(SQLBackend);

}).call(this);
