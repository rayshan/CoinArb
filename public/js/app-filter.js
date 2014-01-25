// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('CaApp').filter('pct', function() {
    return function(input) {
      if (input !== 0) {
        if (Math.abs(input) < 1) {
          return "" + ((input * 1).toFixed(2)) + " %";
        } else if (Math.abs(input) < 10) {
          return "" + ((input * 1).toFixed(1)) + " %";
        } else {
          return "" + ((input * 1).toFixed(0)) + " %";
        }
      }
    };
  });

  angular.module('CaApp').filter('round', function() {
    return function(input) {
      return (input * 1).toFixed(2);
    };
  });

  angular.module('CaApp').filter('toArray', function() {
    return function(input) {
      var i, out;
      out = [];
      for (i in input) {
        out.push(input[i]);
      }
      return out;
    };
  });

}).call(this);

/*
//@ sourceMappingURL=app-filter.map
*/
