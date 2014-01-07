angular.module('app', [
	'ngAnimate',
	'btford.socket-io'
])

angular.module('app').run (tickerSvc) ->
	return

angular.module('app').factory 'exchangeSvc', () ->
	exchanges:
		mtGox: # apiDoc: 'https://bitbucket.org/nitrous/mtgox-api'
			name: 'Mt. Gox',
			currency: '$',
			site: 'https://mtgox.com/',
			url: 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

angular.module('app').factory 'tickerSvc', (exchangeSvc, $http, $timeout) ->
	data =
		response: 0
		calls: 0

	poller = () ->
		$http.get('https://data.btcchina.com/data/ticker').then((res) ->
			data.response = res.data.ticker.last
			data.calls++
			$timeout(poller, 1000)
		)

	poller()

	data: data

angular.module('app').factory 'socket', (socketFactory) ->
	socketFactory({
		ioSocket: io.connect 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
#		ioSocket: io.connect 'https://socketio.mtgox.com:443/mtgox?Currency=USD', {secure: true}
	})

angular.module('app').controller 'AppCtrl', (socket, tickerSvc) ->
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

	for channel, obj of @unsubscribe
		socket.send(JSON.stringify(obj))

	socket.on 'message', (res) =>
		try @price = res.ticker.last.display_short

	@price2 = tickerSvc.data

	return