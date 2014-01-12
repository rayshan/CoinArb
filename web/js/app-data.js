// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('app').factory('exchangeSvc', function() {
    var data;
    data = {
      mtgox: {
        id: 'mtgox',
        displayNameEng: 'Mt. Gox',
        defaultCurrency: 'USD',
        website: 'https://mtgox.com/',
        api: {
          type: 'ws',
          uri: 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
        },
        fetched: {
          current: {
            last: null,
            spread: null,
            updateTime: null,
            error: null
          },
          previous: {
            last: null,
            spread: null,
            updateTime: null,
            error: null
          }
        }
      },
      btcchina: {
        id: 'btcchina',
        displayNameEng: 'BTC China',
        displayNameLocal: '比特币中国',
        defaultCurrency: 'CNY',
        website: 'https://btcchina.com',
        api: {
          type: 'REST',
          uri: 'https://data.btcchina.com/data/ticker',
          rateLimit: 1000 * 5
        },
        fetched: {
          current: {
            last: null,
            spread: null,
            updateTime: null,
            error: null
          },
          previous: {
            last: null,
            spread: null,
            updateTime: null,
            error: null
          }
        }
      },
      localbitcoins: {
        id: 'localbitcoins',
        displayNameEng: 'LocalBitcoins.com',
        defaultCurrency: 'USD',
        website: 'https://localbitcoins.com',
        api: {
          type: 'REST',
          uri: 'https://api.bitcoinaverage.com/exchanges/USD',
          rateLimit: 1001 * 60
        },
        fetched: {
          current: {
            last: null,
            spread: null,
            updateTime: null,
            error: null
          },
          previous: {
            last: null,
            spread: null,
            updateTime: null,
            error: null
          }
        }
      }
    };
    return {
      data: data
    };
  });

}).call(this);

/*
//@ sourceMappingURL=app-data.map
*/