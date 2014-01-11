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
	data =
		mtgox:
			id: 'mtgox' # based on bitcoinaverage
			displayNameEng: 'Mt. Gox'
			defaultCurrency: 'USD'
			website: 'https://mtgox.com/'
			api:
				type: 'ws'
				uri: 'https://data.mtgox.com/api/2/BTCUSD/money/ticker_fast'
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
		btcchina:
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
		localbitcoins:
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

	data: data

angular.module('app').factory 'notificationSvc', () ->
	enabled: false
	create:
		(data) ->
			if Notification.permission != 'granted'
				Notification.requestPermission()

			n = new Notification 'yo', {
				body: data
			}
			return

angular.module('app').factory 'tickerSvc', (exchangeSvc, $http, $timeout, $resource, poller, notificationSvc, $rootScope, $filter) ->
	USDCNY = 6.05
	pollers = []

	checkAndCopy = (id, current) ->
		now = moment().second()
		data = exchangeSvc.data[id].fetched

		check = current.bid != data.current.bid or current.ask != data.current.ask or current.last != data.current.last

		if check
			current.updateTime = now
			angular.copy(data.current, data.previous)
			angular.copy(current, data.current)

			console.log(current)
			console.log(exchangeSvc.data[id].fetched)

#			if notificationSvc.enabled
#				notificationSvc.create(exchangeSvc.data[id].fetched.current.last)

			$rootScope.$broadcast("#{id}Update")
		return

	callback =
		btcchina:
			(res) ->
				id = "btcchina"

				current =
					bid: $filter('round')((res.ticker.buy / USDCNY), 2)
					ask: $filter('round')((res.ticker.sell / USDCNY), 2)
					last: $filter('round')((res.ticker.last / USDCNY), 2)
					updateTime: null
					error: null

				checkAndCopy(id, current)

				return

		localbitcoins:
			(res) ->
#				now = moment()
#				console.log("local")
#				console.log(res)
#				console.log(now)
				return

	for name, data of exchangeSvc.data
		if data.api.type == "REST"
			myResource = $resource data.api.uri

			pollers.push({
				id: name
				item:
					poller.get myResource, {
						action: 'get'
						delay: 1000 * 5 # * 60 # 1 min due to bitcoinaverage api rate limit
					}
				}
			)

	for poller in pollers
		poller.item.promise.then(null, null, callback[poller.id])

	return

angular.module('app').factory 'socket', (socketFactory) ->
	socketFactory({
		ioSocket: io.connect 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
#		ioSocket: io.connect 'https://socketio.mtgox.com:443/mtgox?Currency=USD', {secure: true}
	})

angular.module('app').controller 'AppCtrl', (socket, exchangeSvc, $scope) ->
	@price = undefined
#	@price2 = undefined

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

	$scope.$on("btcchinaUpdate", (event, data) =>
		@price2 = exchangeSvc.data["btcchina"].fetched.current.last
	)

	return