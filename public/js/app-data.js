// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('app').factory('exchangeSvc', function() {
    var data;
    data = {
      mtgox: {
        id: 'mtgox',
        order: 1,
        show: true,
        displayNameEng: 'Mt. Gox',
        geo: "JP",
        defaultCurrency: 'USD',
        website: 'https://mtgox.com/',
        api: {
          type: 'ws',
          uri: 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
        },
        fetched: {
          initialized: false
        }
      },
      btcchina: {
        id: 'btcchina',
        order: 3,
        show: true,
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
          initialized: false
        }
      },
      localbitcoins: {
        id: 'localbitcoins',
        order: 4,
        show: true,
        displayNameEng: 'LocalBitcoins',
        defaultCurrency: 'USD',
        website: 'https://localbitcoins.com',
        api: {
          type: 'REST',
          uri: 'https://api.bitcoinaverage.com/exchanges/USD',
          rateLimit: 1001 * 60
        },
        fetched: {
          initialized: false
        }
      },
      btce: {
        id: 'btce',
        order: 2,
        show: true,
        displayNameEng: 'BTC-e',
        geo: 'BG',
        defaultCurrency: 'USD',
        website: 'https://btc-e.com/',
        api: {
          type: 'REST',
          uri: 'https://api.bitcoinaverage.com/exchanges/USD',
          rateLimit: 1001 * 60
        },
        fetched: {
          initialized: false
        }
      },
      bitstamp: {
        id: 'bitstamp',
        order: 5,
        show: true,
        displayNameEng: 'Bitstamp',
        geo: 'GB',
        defaultCurrency: 'GBP',
        website: 'https://www.bitstamp.net/',
        api: {
          type: 'REST',
          uri: 'https://api.bitcoinaverage.com/exchanges/USD',
          rateLimit: 1001 * 60
        },
        fetched: {
          initialized: false
        }
      },
      bitfinex: {
        id: 'bitfinex',
        order: 6,
        show: true,
        displayNameEng: 'Bitfinex',
        geo: 'HK',
        defaultCurrency: 'HKD',
        website: 'https://www.bitfinex.com/',
        api: {
          type: 'REST',
          uri: 'https://api.bitcoinaverage.com/exchanges/USD',
          rateLimit: 1001 * 60
        },
        fetched: {
          initialized: false
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
