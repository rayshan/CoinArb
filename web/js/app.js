// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('app', ['ngResource', 'ngAnimate', 'btford.socket-io', 'poller']);

  angular.module('app').run(function(tickerSvc) {});

  angular.module('app').factory('exchangeSvc', function() {
    var data;
    data = [
      {
        id: 'mtgox',
        displayNameEng: 'Mt. Gox',
        defaultCurrency: 'USD',
        website: 'https://mtgox.com/',
        api: {
          type: 'ws',
          uri: 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'
        },
        fetched: {
          current: {
            bid: null,
            ask: null,
            last: null,
            updateTime: null,
            error: null
          },
          previous: {
            bid: null,
            ask: null,
            last: null,
            updateTime: null,
            error: null
          }
        }
      }, {
        id: 'btcchina',
        displayName: 'BTC China',
        displayNameLocal: '比特币中国',
        defaultCurrency: 'CNY',
        website: 'https://btcchina.com',
        api: {
          type: 'REST',
          uri: 'https://data.btcchina.com/data/ticker'
        },
        fetched: {
          current: {
            bid: null,
            ask: null,
            last: null,
            updateTime: null,
            error: null
          },
          previous: {
            bid: null,
            ask: null,
            last: null,
            updateTime: null,
            error: null
          }
        }
      }, {
        id: 'localbitcoins',
        displayName: 'LocalBitcoins.com',
        defaultCurrency: 'USD',
        website: 'https://localbitcoins.com',
        api: {
          type: 'REST',
          uri: 'https://api.bitcoinaverage.com/exchanges/USD'
        },
        fetched: {
          current: {
            bid: null,
            ask: null,
            last: null,
            updateTime: null,
            error: null
          },
          previous: {
            bid: null,
            ask: null,
            last: null,
            updateTime: null,
            error: null
          }
        }
      }
    ];
    return {
      data: data
    };
  });

  angular.module('app').factory('tickerSvc', function(exchangeSvc, $http, $timeout, $resource, poller) {
    var callback, myPoller, myResource, uri;
    uri = 'https://api.bitcoinaverage.com/exchanges/USD';
    callback = function(res) {
      var now;
      now = moment();
      console.log(res);
      return console.log(now);
    };
    myResource = $resource(uri);
    myPoller = poller.get(myResource, {
      action: 'get',
      delay: 1000 * 60
    });
    myPoller.promise.then(null, null, callback);
  });

  angular.module('app').factory('socket', function(socketFactory) {
    return socketFactory({
      ioSocket: io.connect('http://socketio.mtgox.com:80/mtgox?Currency=USD')
    });
  });

  angular.module('app').controller('AppCtrl', function(socket, exchangeSvc, $scope) {
    var channel, obj, _ref,
      _this = this;
    this.price = void 0;
    this.unsubscribe = {
      depthBTCUSD: {
        op: 'unsubscribe',
        channel: '24e67e0d-1cad-4cc0-9e7a-f8523ef460fe'
      },
      tradeBTC: {
        op: 'unsubscribe',
        channel: 'dbf1dee9-4f2e-4a08-8cb7-748919a71b21'
      }
    };
    socket.on('connect', function() {
      console.log("Connected.");
    });
    _ref = this.unsubscribe;
    for (channel in _ref) {
      obj = _ref[channel];
      socket.send(JSON.stringify(obj));
    }
    socket.on('message', function(res) {
      try {
        _this.price = res.ticker.last.display_short;
      } catch (_error) {}
    });
  });

}).call(this);

/*
//@ sourceMappingURL=app.map
*/
