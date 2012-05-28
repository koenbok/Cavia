(function() {
  var stubs;

  if (typeof exports === "undefined" || exports === null) exports = {};

  stubs = {
    util: {
      inspect: function() {}
    }
  };

  window.sqlbt = exports;

  window.require = function(name) {
    var lib;
    console.log("[require] " + name);
    lib = window.sqlbt[name];
    return lib != null ? lib : lib = stubs[name];
  };

}).call(this);
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
(function() {
  var Store, async, inspect, log, utils, _,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  require("coffee-script");

  inspect = require("util").inspect;

  async = require("async");

  _ = require("underscore");

  log = require("winston");

  utils = require("./utils");

  Store = (function() {

    function Store(backend, definition) {
      this.backend = backend;
      this.definition = definition;
    }

    Store.prototype.create = function(callback) {
      var item, steps, _i, _len, _ref,
        _this = this;
      steps = [];
      _ref = this.definition;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        steps.push(function(cb) {
          return _this.createKind(item.kind, cb);
        });
        steps.push(function(cb) {
          return async.map(_.keys(item.indexes), function(indexName, cb) {
            var index;
            index = item.indexes[indexName];
            return _this.createIndex(item.kind, index.type, indexName, cb);
          }, cb);
        });
      }
      return async.series(steps, function() {
        return callback();
      });
    };

    Store.prototype.destroy = function(callback) {
      var _this = this;
      return async.map(this.definition, function(item, cb) {
        return _this.backend.dropTable(item.kind, cb);
      }, callback);
    };

    Store.prototype.createKind = function(name, callback) {
      var columns, indexes, steps,
        _this = this;
      columns = {
        value: "text"
      };
      indexes = [];
      steps = [
        function(cb) {
          return _this.backend.createTable(name, cb);
        }, function(cb) {
          return async.map(_.keys(columns), function(column, icb) {
            return _this.backend.createColumn(name, column, columns[column], icb);
          }, cb);
        }, function(cb) {
          return async.map(indexes, function(columns, icb) {
            return _this.createIndex(name, "string", columns, icb);
          }, cb);
        }
      ];
      return async.series(steps, function(error, results) {
        return callback(error, results);
      });
    };

    Store.prototype.createIndex = function(kind, type, name, callback) {
      var indexName, steps,
        _this = this;
      indexName = "" + kind + "_index_" + name;
      if (__indexOf.call(_.keys(this.backend.typeMap), type) < 0) {
        throw "Requested index type '" + type + "' not supported by backend " + (_.keys(this.backend.typeMap));
      }
      steps = [];
      if (name !== "keycol") {
        steps.push(function(cb) {
          return _this.backend.createColumn(kind, indexName, type, cb);
        });
      }
      steps.push(function(cb) {
        return _this.backend.createIndex(kind, indexName, [indexName], cb);
      });
      return async.series(steps, callback);
    };

    Store.prototype.put = function(data, callback) {
      var item, kind, putd, _i, _len;
      if (!_.isArray(data)) data = [data];
      kind = null;
      putd = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        item = data[_i];
        if (!kind) {
          kind = item.kind;
        } else {
          if (!kind === item.kind) throw "Put should all be same kind";
        }
        putd.push(this._toStore(kind, item));
      }
      return this.backend.createOrUpdateRows(kind, putd, callback);
    };

    Store.prototype.get = function(kind, key, callback) {
      if (_.isArray(key)) {
        return this.query(kind, {
          "keycol": ["IN (" + (utils.oinks(key)) + ")", key]
        }, callback);
      } else {
        return this.query(kind, {
          "keycol": ["= ?", key]
        }, function(err, result) {
          if (result.length === 1) {
            return callback(err, result[0]);
          } else {
            return callback(err, null);
          }
        });
      }
    };

    Store.prototype.del = function(kind, key, callback) {
      if (_.isArray(key)) {
        return this.backend["delete"](kind, {
          "keycol": ["IN (" + (utils.oinks(key)) + ")", key]
        }, callback);
      } else {
        return this.backend["delete"](kind, {
          "keycol": ["= ?", key]
        }, callback);
      }
    };

    Store.prototype.query = function(kind, filters, callback) {
      var _this = this;
      if (!callback && _.isFunction(filters)) {
        callback = filters;
        filters = {};
      }
      return this.backend.fetch(kind, filters, function(err, rows) {
        return callback(err, rows.map(function(row) {
          return _this._fromStore(kind, row);
        }));
      });
    };

    Store.prototype._toStore = function(kind, data) {
      var dataCopy, index, indexName, item, key, name, result, _i, _len, _ref, _ref2;
      if (!data.key) data.key = utils.uuid();
      key = data.key;
      kind = data.kind;
      dataCopy = _.clone(data);
      delete dataCopy.key;
      delete dataCopy.kind;
      result = {
        keycol: data.key,
        value: JSON.stringify(dataCopy)
      };
      _ref = this.definition;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        _ref2 = item.indexes;
        for (name in _ref2) {
          index = _ref2[name];
          indexName = "" + kind + "_index_" + name;
          result[indexName] = index.getter(dataCopy);
        }
      }
      return result;
    };

    Store.prototype._fromStore = function(kind, row) {
      var result;
      result = JSON.parse(row.value);
      result.key = row.keycol;
      result.kind = kind;
      return result;
    };

    return Store;

  })();

  exports.Store = Store;

}).call(this);
