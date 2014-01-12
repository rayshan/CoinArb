angular.module('app').factory 'exchangeSvc', () ->
	data =
		mtgox:
			id: 'mtgox' # based on bitcoinaverage
			displayNameEng: 'Mt. Gox'
			defaultCurrency: 'USD'
			website: 'https://mtgox.com/'
			api:
				type: 'ws'
				uri: 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
		# uri: 'https://data.mtgox.com/api/2/BTCUSD/money/ticker_fast' # REST api - https://bitbucket.org/nitrous/mtgox-api
			fetched:
				current:
					last: null
					spread: null
					updateTime: null
					error: null
				previous:
					last: null
					spread: null
					updateTime: null
					error: null
		btcchina:
			id: 'btcchina'
			displayNameEng: 'BTC China'
			displayNameLocal: '比特币中国'
			defaultCurrency: 'CNY'
			website: 'https://btcchina.com'
			api:
				type: 'REST'
				uri: 'https://data.btcchina.com/data/ticker'
				rateLimit: 1000 * 5
			fetched:
				current:
					last: null
					spread: null
					updateTime: null
					error: null
				previous:
					last: null
					spread: null
					updateTime: null
					error: null
		localbitcoins:
			id: 'localbitcoins'
			displayNameEng: 'LocalBitcoins.com'
			defaultCurrency: 'USD'
			website: 'https://localbitcoins.com'
			api:
				type: 'REST'
				uri: 'https://api.bitcoinaverage.com/exchanges/USD' # appears to pull avg_3h
			# uri: 'https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/' # no Access-Control-Allow-Origin header for CORS
				rateLimit: 1001 * 60
			fetched:
				current:
					last: null
					spread: null
					updateTime: null
					error: null
				previous:
					last: null
					spread: null
					updateTime: null
					error: null

	data: data