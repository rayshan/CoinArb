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
        changed = current.last !== data.current.last || current.spread !== data.current.spread;
        if (changed) {
          current.updateTime = now;
          angular.copy(data.current, data.previous);
          angular.copy(current, data.current);
          if (notificationSvc.enabled) {
            notificationSvc.create(exchangeSvc.data[id].fetched.current.last);
          }
          $rootScope.$broadcast("tickerUpdate");
        }
      }
    };
  });

  angular.module('app').factory('tickerSvc', function($resource, $filter, poller, socketSvc, exchangeSvc, checkAndCopySvc) {
    var USDCNY, callback, data, myResource, name, pollers, _i, _len, _ref;
    USDCNY = 6.05;
    pollers = [];
    callback = {
      btcchina: function(res) {
        var current, id;
        id = "btcchina";
        current = {
          spread: $filter('round')((res.ticker.buy - res.ticker.sell) / USDCNY),
          last: $filter('round')(res.ticker.last / USDCNY),
          updateTime: null,
          error: null
        };
        checkAndCopySvc.process(id, current);
      },
      localbitcoins: function(res) {
        var current, id;
        id = "localbitcoins";
        current = {
          spread: res[id].rates.bid - res[id].rates.ask,
          last: res[id].rates.last,
          updateTime: null,
          error: null
        };
        checkAndCopySvc.process(id, current);
      }
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
      poller.item.promise.then(null, null, callback[poller.id]);
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
        socket.on('connect', function() {
          $rootScope.$broadcast('socketConnected');
          console.log('connected');
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
    this.cols = 12 / Object.keys(this.data).length;
    this.baseline = null;
    $scope.$on("tickerUpdate", function() {
      return _this.data = exchangeSvc.data;
    });
    this.diff = function(cur, pre, pct) {
      if (pct = true) {
        return (cur - pre) / pre * 100;
      } else {
        return cur - pre;
      }
    };
    this.show = function(input, equality) {
      return !isNaN(parseFloat(input)) && isFinite(input) && Math.abs(input) > equality;
    };
  });

}).call(this);

/*
//@ sourceMappingURL=app.map
*/
