(function() {
  var Backend, DeleteQuery, SelectQuery, async, inspect, log, utils, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  _ = require("underscore");

  log = require("winston");

  async = require("async");

  utils = require("./utils");

  inspect = require("util").inspect;

  SelectQuery = require("./query").SelectQuery;

  DeleteQuery = require("./query").DeleteQuery;

  Backend = (function() {

    function Backend() {}

    return Backend;

  })();

  exports.SQLBackend = (function(_super) {

    __extends(SQLBackend, _super);

    function SQLBackend() {
      this.disconnect = __bind(this.disconnect, this);
      this.connect = __bind(this.connect, this);
      SQLBackend.__super__.constructor.apply(this, arguments);
    }

    SQLBackend.prototype.connect = function() {
      this._connected = true;
      return this._connect();
    };

    SQLBackend.prototype.disconnect = function() {
      if (!this._connected) return;
      this._connected = false;
      return this._disconnect();
    };

    SQLBackend.prototype._connect = function() {};

    SQLBackend.prototype._disconnect = function() {};

    SQLBackend.prototype.execute = function(sql, params, callback) {
      var cb,
        _this = this;
      if (!this._connected) this.connect();
      if (_.isFunction(params)) {
        callback = params;
        params = [];
      }
      if (this.log) log.debug("[sql] " + sql + " " + (inspect(params)));
      cb = function(err, result) {
        clearTimeout(_this._disconnectTimer);
        _this._disconnectTimer = setTimeout(function() {
          return _this.disconnect();
        }, 1000);
        if (err) throw err;
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
      if (_.isArray(columns)) columns = columns.join(',');
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
      var steps, worker,
        _this = this;
      worker = function(task, cb) {
        return task(cb);
      };
      if (this.transactionQueue == null) {
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
