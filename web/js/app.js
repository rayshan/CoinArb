// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('app', ['ngResource', 'ngAnimate', 'btford.socket-io', 'poller']);

  angular.module('app').run(function(tickerSvc) {});

  angular.module('app').factory('notificationSvc', function() {
    return {
      enabled: false,
      create: function(data) {
        var n;
        if (Notification.permission !== 'granted') {
          Notification.requestPermission();
        }
        n = new Notification('yo', {
          body: data
        });
      }
    };
  });

  angular.module('app').factory('checkAndCopySvc', function($rootScope, exchangeSvc, notificationSvc) {
    return {
      process: function(id, current) {
        var changed, data, now;
        now = moment();
        data = exchangeSvc.data[id].fetched;
        if (data.initialized === false) {
          data.initialized = true;
          current.updateTime = now;
          data.current = {};
          angular.copy(current, data.current);
          if (notificationSvc.enabled) {
            notificationSvc.create(exchangeSvc.data[id].fetched.current.last);
          }
          $rootScope.$broadcast("tickerUpdate");
        } else {
          changed = current.last !== data.current.last || current.spread !== data.current.spread;
          if (changed) {
            current.updateTime = now;
            if (data.previous == null) {
              data.previous = {};
            }
            angular.copy(data.current, data.previous);
            angular.copy(current, data.current);
            if (notificationSvc.enabled) {
              notificationSvc.create(exchangeSvc.data[id].fetched.current.last);
            }
            $rootScope.$broadcast("tickerUpdate");
          }
        }
      }
    };
  });

  angular.module('app').factory('tickerSvc', function($resource, $filter, poller, socketSvc, exchangeSvc, checkAndCopySvc) {
    var USDCNY, callback, data, myResource, name, pollers, _i, _len, _ref;
    USDCNY = 6.05;
    pollers = [];
    callback = function(id) {
      return function(res) {
        var current;
        switch (id) {
          case "btcchina":
            current = {
              spread: $filter('round')((res.ticker.buy - res.ticker.sell) / USDCNY),
              last: $filter('round')(res.ticker.last / USDCNY),
              updateTime: null
            };
            return checkAndCopySvc.process(id, current);
          default:
            current = {
              spread: $filter('round')(res[id].rates.bid - res[id].rates.ask),
              last: $filter('round')(res[id].rates.last),
              updateTime: null
            };
            return checkAndCopySvc.process(id, current);
        }
      };
    };
    _ref = exchangeSvc.data;
    for (name in _ref) {
      data = _ref[name];
      if (data.api.type === "REST") {
        myResource = $resource(data.api.uri);
        pollers.push({
          id: name,
          item: poller.get(myResource, {
            action: 'get',
            delay: data.api.rateLimit
          })
        });
      } else {
        socketSvc.process(data);
      }
    }
    for (_i = 0, _len = pollers.length; _i < _len; _i++) {
      poller = pollers[_i];
      poller.item.promise.then(null, null, callback(poller.id));
    }
  });

  angular.module('app').factory('socketSvc', function($rootScope, $filter, socketFactory, checkAndCopySvc) {
    var unsubscribe;
    unsubscribe = {
      depthBTCUSD: {
        op: 'unsubscribe',
        channel: '24e67e0d-1cad-4cc0-9e7a-f8523ef460fe'
      },
      tradeBTC: {
        op: 'unsubscribe',
        channel: 'dbf1dee9-4f2e-4a08-8cb7-748919a71b21'
      }
    };
    return {
      process: function(data) {
        var channel, obj, socket;
        socket = socketFactory({
          ioSocket: io.connect(data.api.uri)
        });
        for (channel in unsubscribe) {
          obj = unsubscribe[channel];
          socket.send(JSON.stringify(obj));
        }
        socket.on('message', function(res) {
          var current;
          if (res.op.indexOf("subscribe") === -1 && res.channel_name.indexOf("ticker") !== -1) {
            current = {
              spread: $filter('round')(res.ticker.buy.value - res.ticker.sell.value),
              last: $filter('round')(res.ticker.last.value),
              updateTime: null,
              error: null
            };
            checkAndCopySvc.process(data.id, current);
          }
        });
      }
    };
  });

  angular.module('app').controller('AppCtrl', function($scope, exchangeSvc) {
    var _this = this;
    this.data = exchangeSvc.data;
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
    this.baseline = "mtgox";
    this.currency = "USD";
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
    });
  });

}).call(this);

/*
//@ sourceMappingURL=app.map
*/
