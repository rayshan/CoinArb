// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('app').directive('caNumDisplay', function() {
    return {
      templateUrl: 'partials/ca-num-display.html',
      transclude: true,
      restrict: 'E',
      scope: {
        name: "@",
        type: "@",
        cur: "=",
        pre: "=",
        show: "&",
        diff: "&"
      },
      link: function(scope, ele, attrs) {}
    };
  });

}).call(this);

/*
//@ sourceMappingURL=app-dir.map
*/
