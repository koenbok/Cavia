(function() {
  var Backend, async, log, utils, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  async = require("async");

  _ = require("underscore");

  log = require("winston");

  utils = require("./utils");

  Backend = (function() {

    function Backend() {}

    return Backend;

  })();

  exports.SQLBackend = (function(_super) {

    __extends(SQLBackend, _super);

    function SQLBackend() {
      SQLBackend.__super__.constructor.apply(this, arguments);
    }

    SQLBackend.prototype.createTable = function(name, callback) {
      return this.execute("CREATE TABLE " + name + " (keycol CHAR(32) NOT NULL, PRIMARY KEY (keycol))", callback);
    };

    SQLBackend.prototype.dropTable = function(name, callback) {
      return this.execute("DROP TABLE IF EXISTS " + name, callback);
    };

    SQLBackend.prototype.createColumn = function(table, name, type, callback) {
      return this.execute("ALTER TABLE " + table + " ADD COLUMN " + name + " " + this.typeMap[type], callback);
    };

    SQLBackend.prototype.createIndex = function(table, name, columns, callback) {
      return this.execute("CREATE INDEX " + name + " ON " + table + " (" + (columns.join(',')) + ")", callback);
    };

    SQLBackend.prototype.createOrUpdateRow = function(table, columns, callback) {
      var keys, values;
      keys = _.keys(columns);
      values = _.values(columns);
      return this.execute("INSERT OR REPLACE INTO " + table + " (" + (keys.join(', ')) + ") VALUES (" + (utils.oinks(values)) + ")", values, callback);
    };

    SQLBackend.prototype.createOrUpdateRows = function(table, rows, callback) {
      var steps,
        _this = this;
      if (rows.length === 1) {
        this.createOrUpdateRow(table, rows[0], callback);
        return;
      }
      steps = [
        function(cb) {
          return _this.execute("BEGIN", cb);
        }, function(cb) {
          return async.map(rows, function(columns, icb) {
            return _this.createOrUpdateRow(table, columns, icb);
          }, cb);
        }, function(cb) {
          return _this.execute("COMMIT", cb);
        }
      ];
      return async.series(steps, callback);
    };

    SQLBackend.prototype.filter = function(filters) {
      var column, filter, sql, val;
      if (filters !== {}) return ["", []];
      val = [];
      sql = [" WHERE"];
      for (column in filters) {
        filter = filters[column];
        if (val.length > 0) sql.push(" AND");
        sql.push(" " + column + " " + filter[0]);
        val.push(filter[1]);
      }
      return [sql.join(""), val];
    };

    SQLBackend.prototype.fetch = function(table, filters, callback) {
      var res;
      res = this.filter(filters);
      return this.execute("SELECT * FROM " + table + res[0], res[1], callback);
    };

    SQLBackend.prototype["delete"] = function(table, filters, callback) {
      var res;
      res = this.filter(filters);
      return this.execute("DELETE FROM " + table + res[0], res[1], callback);
    };

    return SQLBackend;

  })(Backend);

}).call(this);
