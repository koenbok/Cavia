(function() {
  var _;

  _ = require("underscore");

  exports.uuid = function() {
    var chars, digit, output, r, random;
    chars = '0123456789abcdefghijklmnopqrstuvwxyz'.split('');
    output = new Array(36);
    random = 0;
    for (digit = 1; digit <= 32; digit++) {
      if (random <= 0x02) random = 0x2000000 + (Math.random() * 0x1000000) | 0;
      r = random & 0xf;
      random = random >> 4;
      output[digit] = chars[digit === 19 ? (r & 0x3) | 0x8 : r];
    }
    return output.join('');
  };

  exports.logError = function(err) {
    if (err) return console.log(err);
  };

  exports.placeholders = function(values, placeholder) {
    var i;
    if (placeholder == null) placeholder = "?";
    return [
      (function() {
        var _ref, _results;
        _results = [];
        for (i = 1, _ref = values.length; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
          _results.push(placeholder);
        }
        return _results;
      })()
    ][0].join(", ");
  };

  exports.oinks = exports.placeholders;

}).call(this);
