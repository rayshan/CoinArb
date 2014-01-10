angular.module('app', [
	'ngResource'
	'ngAnimate'
	'btford.socket-io'
	'poller'
])

angular.module('app').run (tickerSvc) ->
	# excute immediately on app bootstrap
	return

angular.module('app').factory 'exchangeSvc', () ->
	data = [
		{
			id: 'mtgox' # based on bitcoinaverage
			displayNameEng: 'Mt. Gox'
			defaultCurrency: 'USD'
			website: 'https://mtgox.com/'
			api:
				type: 'ws'
				uri: 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'
			fetched:
				current:
					bid: null
					ask: null
					last: null
					updateTime: null
					error: null
				previous:
					bid: null
					ask: null
					last: null
					updateTime: null
					error: null
			# REST api - https://bitbucket.org/nitrous/mtgox-api
		}
		{
			id: 'btcchina'
			displayName: 'BTC China'
			displayNameLocal: '比特币中国'
			defaultCurrency: 'CNY'
			website: 'https://btcchina.com'
			api:
				type: 'REST'
				uri: 'https://data.btcchina.com/data/ticker'
			fetched:
				current:
					bid: null
					ask: null
					last: null
					updateTime: null
					error: null
				previous:
					bid: null
					ask: null
					last: null
					updateTime: null
					error: null
		}
		{
			id: 'localbitcoins'
			displayName: 'LocalBitcoins.com'
			defaultCurrency: 'USD'
			website: 'https://localbitcoins.com'
			api:
				type: 'REST'
				uri: 'https://api.bitcoinaverage.com/exchanges/USD'
				# uri: 'https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/' # no Access-Control-Allow-Origin header for CORS
			fetched:
				current:
					bid: null
					ask: null
					last: null
					updateTime: null
					error: null
				previous:
					bid: null
					ask: null
					last: null
					updateTime: null
					error: null
		}
	]

	data: data

#angular.module('app').factory 'tickerSvc', (exchangeSvc, $http, $timeout) ->
#	poller1: (url, assignee) ->
#		$http.get(url).then((res) ->
#			exchangeSvc.data.btcChina.price.current = res.data.ticker.last
#			$timeout(poller1, 1000)
#		)

angular.module('app').factory 'tickerSvc', (exchangeSvc, $http, $timeout, $resource, poller) ->
#	poller1 = (url, ref) ->
#		$http.get(url).then((res) ->
#			console.log(res)
##			ref = res.data.ticker.last
#			$timeout(poller1, 1000)
#			return
#		)
#
#	for exchange, data of exchangeSvc.data
#		if data.api.type == 'REST'
#			poller1(data.api.uri, data.fetched.price.current)

#	poller1()

	uri = 'https://api.bitcoinaverage.com/exchanges/USD'

	callback = (res) ->
		now = moment()
		console.log(res)
		console.log(now)

	myResource = $resource uri

	myPoller = poller.get myResource, {
		action: 'get'
		delay: 1000 * 60
	}

	myPoller.promise.then(null, null, callback)

	return

angular.module('app').factory 'socket', (socketFactory) ->
	socketFactory({
		ioSocket: io.connect 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
#		ioSocket: io.connect 'https://socketio.mtgox.com:443/mtgox?Currency=USD', {secure: true}
	})

angular.module('app').controller 'AppCtrl', (socket, exchangeSvc, $scope) ->
	@price = undefined

	@unsubscribe =
		depthBTCUSD:
			op: 'unsubscribe'
			channel: '24e67e0d-1cad-4cc0-9e7a-f8523ef460fe'
		tradeBTC:
			op: 'unsubscribe'
			channel: 'dbf1dee9-4f2e-4a08-8cb7-748919a71b21'

	socket.on 'connect', () ->
		console.log("Connected.")
		return

	for channel, obj of @unsubscribe
		socket.send(JSON.stringify(obj))

	socket.on 'message', (res) =>
		try @price = res.ticker.last.display_short
		return

#	$scope.$watch (() -> exchangeSvc.data.btcChina.fetched.price.current), (newVal, oldVal) =>
#		@price2 = newVal
#		console.log(@price2)
#		return

	return