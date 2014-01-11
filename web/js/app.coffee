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
			displayNameEng: 'LocalBitcoins.com'
			defaultCurrency: 'USD'
			website: 'https://localbitcoins.com'
			api:
				type: 'REST'
				uri: 'https://api.bitcoinaverage.com/exchanges/USD'
				# uri: 'https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/' # no Access-Control-Allow-Origin header for CORS
				rateLimit: 1001 * 60
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

angular.module('app').factory 'checkAndCopySvc', ($rootScope, exchangeSvc, notificationSvc) ->
	process: (id, current) ->
		now = moment().second()
		data = exchangeSvc.data[id].fetched

		changed = current.bid != data.current.bid or current.ask != data.current.ask or current.last != data.current.last

		if changed
			current.updateTime = now
			angular.copy(data.current, data.previous)
			angular.copy(current, data.current)

			if notificationSvc.enabled
				notificationSvc.create(exchangeSvc.data[id].fetched.current.last)

#			$rootScope.$broadcast("#{id}Update")
			$rootScope.$broadcast("tickerUpdate")
		return

angular.module('app').factory 'tickerSvc', ($resource, $filter, exchangeSvc, poller, checkAndCopySvc) ->
	USDCNY = 6.05
	pollers = []

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
				checkAndCopySvc.process(id, current)
				return
		localbitcoins:
			(res) ->
				id = "localbitcoins"
				current =
					bid: res[id].rates.bid
					ask: res[id].rates.ask
					last: res[id].rates.last
					updateTime: null
					error: null
				checkAndCopySvc.process(id, current)
				return

	for name, data of exchangeSvc.data
		if data.api.type == "REST"
			myResource = $resource data.api.uri

			pollers.push({
				id: name
				item:
					poller.get myResource, {
						action: 'get'
						delay: data.api.rateLimit
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

angular.module('app').controller 'AppCtrl', ($scope, socket, exchangeSvc) ->
	@data = exchangeSvc.data
	@cols = 12 / Object.keys(@data).length # must be divisible
	console.log(@data)

	$scope.$on "tickerUpdate", () =>
		@data = exchangeSvc.data

#	@price = undefined
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

	return