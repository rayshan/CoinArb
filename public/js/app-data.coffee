#fetched =
#	current:
#		last: null
#		spread: null
#		volume: null
#		updateTime: null
#		error: null
#	previous:
#		last: null
#		spread: null
#		volume: null
#		updateTime: null
#		error: null

angular.module('CaApp').factory 'exchangeSvc', () ->
	data =
		mtgox:
			id: 'mtgox' # based on bitcoinaverage
			order: 1 # always 1st
			show: true
			displayNameEng: 'Mt. Gox'
			geo: "JP" # ISO 3166-1
			defaultCurrency: 'USD'
			website: 'https://mtgox.com/'
			api:
#				type: 'ws'
#				uri: 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
				type: 'REST'
				uri: 'https://data.mtgox.com/api/2/BTCUSD/money/ticker_fast' # REST api - https://bitbucket.org/nitrous/mtgox-api
				rateLimit: 1005
			fetched:
				initialized: false
		btcchina:
			id: 'btcchina'
			order: 3
			show: true
			displayNameEng: 'BTC China'
			displayNameLocal: '比特币中国'
			defaultCurrency: 'CNY'
			website: 'https://btcchina.com'
			api:
				type: 'REST'
				uri: 'https://data.btcchina.com/data/ticker'
				rateLimit: 1000 * 5
			fetched:
				initialized: false
		localbitcoins:
			id: 'localbitcoins'
			order: 4
			show: true
			displayNameEng: 'LocalBitcoins'
			defaultCurrency: 'USD'
			website: 'https://localbitcoins.com'
			api:
				type: 'REST'
#				uri: 'https://api.bitcoinaverage.com/exchanges/USD' # appears to pull avg_3h
				# uri: 'https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/' # no CORS
				uri: 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20json%20where%20url%20%3D%20%22https%3A%2F%2Flocalbitcoins.com%2Fbitcoinaverage%2Fticker-all-currencies%2F%22&format=json&callback='
				# yql
				rateLimit: 1000 * 5
			fetched:
				initialized: false
		btce:
			id: 'btce'
			order: 2
			show: true
			displayNameEng: 'BTC-e'
			geo: 'BG'
			defaultCurrency: 'USD'
			website: 'https://btc-e.com/'
			api:
				type: 'REST'
#				uri: 'https://api.bitcoinaverage.com/exchanges/USD'
#				uri: 'https://btc-e.com/api/2/btc_usd/ticker' # no CORS no JSONP
				uri: 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20json%20where%20url%20%3D%20%22https%3A%2F%2Fbtc-e.com%2Fapi%2F2%2Fbtc_usd%2Fticker%22&format=json&callback='
				# yql, no diagnostics
				rateLimit: 1000 * 5 # yql public 2k requests / hr
			fetched:
				initialized: false
		bitstamp:
			id: 'bitstamp'
			order: 5
			show: true
			displayNameEng: 'Bitstamp'
			geo: 'GB'
			defaultCurrency: 'GBP'
			website: 'https://www.bitstamp.net/'
			api:
				type: 'REST'
				uri: 'https://api.bitcoinaverage.com/exchanges/USD'
				# no cors, 403 when pulled via yql
				rateLimit: 1001 * 60
			fetched:
				initialized: false
		bitfinex:
			id: 'bitfinex'
			order: 6
			show: true
			displayNameEng: 'Bitfinex'
			geo: 'HK'
			defaultCurrency: 'HKD'
			website: 'https://www.bitfinex.com/'
			api:
				type: 'REST'
#				uri: 'https://api.bitcoinaverage.com/exchanges/USD'
				uri: 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20json%20where%20url%20%3D%20%22https%3A%2F%2Fapi.bitfinex.com%2Fv1%2Fticker%2Fbtcusd%22&format=json&callback='
				rateLimit: 1000 * 5
			fetched:
				initialized: false

	data: data