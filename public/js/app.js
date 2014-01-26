// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('CaApp', ['ngResource', 'ngAnimate', 'btford.socket-io', 'poller']);

  angular.module('CaApp').run(function(caTickerSvc) {});

  angular.module('CaApp').controller('CaAppCtrl', function($scope, $interval, exchangeSvc) {
    var _this = this;
    this.getTime = function(timeZone) {
      var now;
      now = moment();
      return now.format('HH:mm:ss');
    };
    this.showTime = function() {
      return true;
    };
    $interval(this.getTime, 1);
    this.data = exchangeSvc.data;
    this.dataChart = "data/data.tsv";
    this.showCount = function() {
      var count, data, exchange, _ref;
      count = 0;
      _ref = this.data;
      for (exchange in _ref) {
        data = _ref[exchange];
        if (data.show === true) {
          count++;
        }
      }
      return count;
    };
    this.cols = 12 / this.showCount();
    this.currency = "USD";
    this.baseline = "mtgox";
    this.baselineBest = null;
    this.setBaseline = function(id) {
      this.baseline = id;
      $scope.$broadcast("baselineSet");
    };
    this.getBaselineBest = function() {
      var baselineDiff, exchange, key, value, _best, _highest, _lasts;
      _lasts = [];
      _highest = null;
      _best = null;
      for (exchange in this.data) {
        if (this.data[exchange].fetched.current != null) {
          _lasts[exchange] = this.data[exchange].fetched.current.last;
        }
      }
      for (key in _lasts) {
        value = _lasts[key];
        if (this.data[this.baseline].fetched.current != null) {
          baselineDiff = Math.abs(value - this.data[this.baseline].fetched.current.last);
          if ((_highest == null) || baselineDiff > _highest) {
            _highest = baselineDiff;
            _best = key;
          }
        }
      }
      this.baselineBest = _best;
    };
    this.hide = function(id) {
      if (this.showCount() > 1) {
        this.data[id].show = false;
        this.cols = 12 / this.showCount();
      } else {
        throw "Must have at least 1 exchange in display.";
      }
    };
    $scope.$on("tickerUpdate", function() {
      _this.data = exchangeSvc.data;
      _this.getBaselineBest();
    });
    $scope.$on("baselineSet", function() {
      _this.getBaselineBest();
    });
  });

}).call(this);

/*
//@ sourceMappingURL=app.map
*/
