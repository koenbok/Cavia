(function() {
  var SQLBackend, async, log, pg, utils, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  async = require("async");

  _ = require("underscore");

  log = require("winston");

  SQLBackend = require("./backend").SQLBackend;

  utils = require("./utils");

  pg = require("pg");

  exports.PostgresBackend = (function(_super) {

    __extends(PostgresBackend, _super);

    function PostgresBackend(dsl) {
      this.typeMap = {
        string: 'VARCHAR(255)',
        text: 'TEXT',
        int: 'INT',
        float: 'FLOAT'
      };
      this.client = new pg.Client(dsl);
      this.client.connect();
    }

    PostgresBackend.prototype.execute = function(sql, params, callback) {
      var cb, n, _ref;
      if (_.isFunction(params)) {
        callback = params;
        params = [];
      }
      if (params !== null && !_.isArray(params)) params = [params];
      for (n = 0, _ref = params.length; 0 <= _ref ? n <= _ref : n >= _ref; 0 <= _ref ? n++ : n--) {
        sql = sql.replace("?", "$" + (n + 1));
      }
      cb = function(err, result) {
        if (err) {
          console.log(sql, params);
          throw err;
        }
        return callback(err, result.rows);
      };
      if (sql.slice(0, 6).toLowerCase() === "select") {
        return this.client.query(sql, params, cb);
      } else {
        return this.client.query(sql, params, cb);
      }
    };

    PostgresBackend.prototype.createOrUpdateRow = function(table, columns, callback) {
      var k, keys, params, sql, v, vals, values;
      keys = _.keys(columns);
      values = _.values(columns);
      vals = [];
      for (k in columns) {
        v = columns[k];
        vals.push("" + k + " = ?");
      }
      sql = "		WITH upsert AS		(			UPDATE " + table + " m SET " + (vals.join(', ')) + " WHERE m.keycol=?			RETURNING m.keycol		)		INSERT INTO " + table + " (" + (keys.join(', ')) + ") 			SELECT " + (utils.oinks(values)) + "			WHERE NOT EXISTS (SELECT 1 FROM upsert)";
      params = [];
      params.push.apply(params, values);
      params.push.apply(params, [columns.keycol]);
      params.push.apply(keys, values);
      params.push.apply(params, values);
      return this.execute(sql, params, callback);
    };

    return PostgresBackend;

  })(SQLBackend);

}).call(this);
