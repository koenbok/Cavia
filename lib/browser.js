// Generated by CoffeeScript 1.3.3
(function() {



}).call(this);
// Generated by CoffeeScript 1.3.3
(function() {
  var Backend, DeleteQuery, SelectQuery, async, inspect, log, pooling, utils, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  _ = require("underscore");

  log = require("winston");

  async = require("async");

  utils = require("./utils");

  inspect = require("util").inspect;

  SelectQuery = require("./query").SelectQuery;

  DeleteQuery = require("./query").DeleteQuery;

  pooling = require("generic-pool");

  Backend = (function() {

    function Backend() {}

    return Backend;

  })();

  exports.SQLBackend = (function(_super) {

    __extends(SQLBackend, _super);

    function SQLBackend() {
      return SQLBackend.__super__.constructor.apply(this, arguments);
    }

    SQLBackend.prototype.setupPool = function() {
      return this.pool = pooling.Pool({
        name: "store",
        create: this.connect,
        destroy: this.disconnect,
        max: this.config.connections,
        idleTimeoutMillis: this.config.timeout * 1000,
        log: false
      });
    };

    SQLBackend.prototype.execute = function(sql, params, callback) {
      var cb, clean,
        _this = this;
      if (!this.pool) {
        this.setupPool();
      }
      if (_.isFunction(params)) {
        callback = params;
        params = [];
      }
      if (this.log) {
        clean = sql.replace(/\s+(?= )/g, '');
        log.debug("sql", "" + clean + " " + (inspect(params)));
      }
      cb = function(err, result) {
        if (err) {
          log.error(err);
        }
        return callback(err, result);
      };
      return this._execute(sql, params, cb);
    };

    SQLBackend.prototype.createTable = function(name, callback) {
      return this.execute("CREATE TABLE " + name + " (" + this.config.keycol + " CHAR(32) NOT NULL, PRIMARY KEY (" + this.config.keycol + "))", callback);
    };

    SQLBackend.prototype.dropTable = function(name, callback) {
      return this.execute("DROP TABLE IF EXISTS " + name, callback);
    };

    SQLBackend.prototype.createColumn = function(table, name, type, callback) {
      return this.execute("ALTER TABLE " + table + " ADD COLUMN " + name + " " + this.typeMap[type], callback);
    };

    SQLBackend.prototype.dropColumn = function(table, name, callback) {
      throw new Error("Not implemented");
    };

    SQLBackend.prototype.createIndex = function(table, name, columns, callback) {
      if (_.isArray(columns)) {
        columns = columns.join(',');
      }
      return this.execute("CREATE INDEX " + name + " ON " + table + " (" + columns + ")", callback);
    };

    SQLBackend.prototype.dropIndex = function(table, name, callback) {
      throw new Error("Not implemented");
    };

    SQLBackend.prototype.query = function(query, callback) {
      return this.execute(query.sql, query.val, callback);
    };

    SQLBackend.prototype.select = function(table, input, callback) {
      var query;
      query = new SelectQuery(table, input, {});
      return this.query(query, callback);
    };

    SQLBackend.prototype["delete"] = function(table, input, callback) {
      var query;
      query = new DeleteQuery(table, input, {});
      return this.query(query, callback);
    };

    SQLBackend.prototype.transaction = function(work, callback) {
      var steps, worker, _ref,
        _this = this;
      worker = function(task, cb) {
        return task(cb);
      };
      if ((_ref = this.transactionQueue) == null) {
        this.transactionQueue = async.queue(worker, 1);
      }
      steps = [];
      steps.push(function(cb) {
        return _this.beginTransaction(cb);
      });
      steps.push(work);
      steps.push(function(cb) {
        return _this.commitTransaction(cb);
      });
      return this.transactionQueue.push(function(cb) {
        return async.series(steps, function(result) {
          cb();
          return callback(result);
        });
      });
    };

    SQLBackend.prototype.beginTransaction = function(callback) {
      return this.execute("BEGIN", callback);
    };

    SQLBackend.prototype.commitTransaction = function(callback) {
      return this.execute("COMMIT", callback);
    };

    SQLBackend.prototype.upsert = function(table, columns, callback) {
      var keys, values;
      keys = _.keys(columns);
      values = _.values(columns);
      return this.execute("INSERT OR REPLACE INTO " + table + " 			(" + (keys.join(', ')) + ") VALUES 			(" + (utils.placeholders(values)) + ")", values, callback);
    };

    return SQLBackend;

  })(Backend);

}).call(this);
// Generated by CoffeeScript 1.3.3
(function() {
  var DeleteQuery, SelectQuery, Store, async, ignoreError, inspect, log, utils, _,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  require("coffee-script");

  inspect = require("util").inspect;

  async = require("async");

  _ = require("underscore");

  log = require("winston");

  SelectQuery = require("./query").SelectQuery;

  DeleteQuery = require("./query").DeleteQuery;

  utils = require("./utils");

  ignoreError = utils.ignoreError;

  Store = (function() {

    function Store(backend, definition) {
      this.backend = backend;
      this.definition = definition;
    }

    Store.prototype.create = function(callback) {
      var steps,
        _this = this;
      steps = [];
      _.map(_.keys(this.definition), function(kindName) {
        var kind;
        kind = _this.definition[kindName];
        steps.push(function(cb) {
          return _this.createKind(kindName, ignoreError(cb));
        });
        return _.map(_.keys(kind.indexes), function(indexName) {
          var index;
          index = kind.indexes[indexName];
          return steps.push(function(cb) {
            return _this.createIndex(kindName, index[0], indexName, ignoreError(cb));
          });
        });
      });
      return async.series(steps, callback);
    };

    Store.prototype.destroy = function(callback) {
      var steps,
        _this = this;
      steps = [];
      _.map(_.keys(this.definition), function(kindName) {
        var kind;
        kind = _this.definition[kindName];
        steps.push(function(cb) {
          return _this.destroyKind(kindName, cb);
        });
        return _.map(_.keys(kind.indexes), function(indexName) {
          var index;
          index = kind.indexes[indexName];
          return steps.push(function(cb) {
            return _this.destroyIndex(kindName, indexName, cb);
          });
        });
      });
      return async.series(steps, callback);
    };

    Store.prototype.createKind = function(name, callback) {
      var columns, steps,
        _this = this;
      columns = {
        value: "text"
      };
      steps = [];
      steps.push(function(cb) {
        return _this.backend.createTable(name, cb);
      });
      _.map(_.keys(columns), function(columnName, cb) {
        return steps.push(function(cb) {
          var column;
          column = columns[columnName];
          return _this.backend.createColumn(name, columnName, column, cb);
        });
      });
      return async.series(steps, callback);
    };

    Store.prototype.destroyKind = function(name, callback) {
      return this.backend.dropTable(name, callback);
    };

    Store.prototype.createIndex = function(kind, type, name, callback) {
      var indexName, indexTableName, steps,
        _this = this;
      indexTableName = "" + kind + "_index_" + name + "_table";
      indexName = "" + kind + "_index_" + name;
      if (__indexOf.call(_.keys(this.backend.typeMap), type) < 0) {
        throw "Requested index type '" + type + "' not supported by backend " + (_.keys(this.backend.typeMap));
      }
      steps = [];
      steps.push(function(cb) {
        return _this.backend.createTable(indexTableName, cb);
      });
      steps.push(function(cb) {
        return _this.backend.createColumn(indexTableName, "value", type, cb);
      });
      steps.push(function(cb) {
        return _this.backend.createIndex(indexTableName, indexName, "value", cb);
      });
      return async.series(steps, callback);
    };

    Store.prototype.destroyIndex = function(kind, name, callback) {
      var indexTableName;
      indexTableName = "" + kind + "_index_" + name + "_table";
      return this.backend.dropTable(indexTableName, callback);
    };

    Store.prototype.get = function(kind, keys, callback) {
      var d, query, single,
        _this = this;
      if (!_.isArray(keys)) {
        keys = [keys];
        single = true;
      }
      d = {};
      d[this.backend.config.keycol + " IN"] = keys;
      query = new SelectQuery(kind, d);
      return this.backend.query(query, function(err, results) {
        var item, key, resultData, resultMap, resultMapped, _i, _j, _len, _len1;
        if (single) {
          if (results[0]) {
            return callback(err, _this._fromStore(kind, results[0]));
          } else {
            return callback(err, null);
          }
        } else {
          resultMap = {};
          resultMapped = [];
          for (_i = 0, _len = results.length; _i < _len; _i++) {
            item = results[_i];
            resultData = _this._fromStore(kind, item);
            resultMap[resultData.key] = resultData;
          }
          for (_j = 0, _len1 = keys.length; _j < _len1; _j++) {
            key = keys[_j];
            resultMapped.push(resultMap[key]);
          }
          return callback(err, resultMapped);
        }
      });
    };

    Store.prototype.put = function(data, callback) {
      var steps, transactionWork,
        _this = this;
      if (!_.isArray(data)) {
        data = [data];
      }
      steps = [];
      _.map(data, function(item) {
        var indexes;
        steps.push(function(cb) {
          return _this.backend.upsert(item.kind, _this._toStore(item.kind, item), cb);
        });
        indexes = _this.definition[item.kind].indexes;
        return _.keys(indexes).map(function(indexName) {
          var index, indexTableName;
          index = indexes[indexName];
          indexTableName = "" + item.kind + "_index_" + indexName + "_table";
          return steps.push(function(cb) {
            var indexData;
            indexData = {};
            indexData[_this.backend.config.keycol] = item.key;
            indexData["value"] = index[1](item);
            return _this.backend.upsert(indexTableName, indexData, cb);
          });
        });
      });
      transactionWork = function(cb) {
        return async.parallel(steps, cb);
      };
      return this.backend.transaction(transactionWork, callback);
    };

    Store.prototype.query = function(kind, filter, options, callback) {
      var column, d, indexTableName, key, operator, subquery, topquery, value,
        _this = this;
      if (callback == null) {
        callback = options;
      }
      if (callback == null) {
        callback = filter;
      }
      if (!filter || !_.keys(filter).length) {
        this.backend.select(kind, {}, function(err, results) {
          return callback(err, _.map(results, function(item) {
            return _this._fromStore(kind, item);
          }));
        });
      }
      for (key in filter) {
        value = filter[key];
        filter = key.split(" ");
        column = filter[0];
        operator = filter[1];
        indexTableName = "" + kind + "_index_" + column + "_table";
        if (__indexOf.call(_.keys(this.definition[kind].indexes), column) < 0) {
          throw new Error("No index for " + kind + "." + column);
        }
        d = {};
        d["value " + operator] = value;
        subquery = new SelectQuery(indexTableName, d, {
          columns: [this.backend.config.keycol]
        });
        d = {};
        d["" + this.backend.config.keycol + " IN"] = subquery;
        topquery = new SelectQuery(kind, d);
        this.backend.query(topquery, function(err, results) {
          return callback(err, _.map(results, function(item) {
            return _this._fromStore(kind, item);
          }));
        });
        return;
      }
    };

    Store.prototype._toStore = function(kind, data) {
      var dataCopy, key, result;
      if (!data.key) {
        data.key = utils.uuid();
      }
      key = data.key;
      kind = data.kind;
      dataCopy = _.clone(data);
      delete dataCopy[this.backend.config.keycol];
      delete dataCopy.kind;
      result = {};
      result[this.backend.config.keycol] = data.key;
      result["value"] = this._serialize(dataCopy);
      return result;
    };

    Store.prototype._fromStore = function(kind, row) {
      var result;
      result = this._deserialize(row.value);
      result.key = row[this.backend.config.keycol];
      result.kind = kind;
      return result;
    };

    Store.prototype._serialize = function(data) {
      return JSON.stringify(data);
    };

    Store.prototype._deserialize = function(str) {
      return JSON.parse(str);
    };

    return Store;

  })();

  exports.Store = Store;

}).call(this);
