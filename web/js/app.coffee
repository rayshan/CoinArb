angular.module('app', [
	'ngAnimate',
	'btford.socket-io'
])

angular.module('app').factory 'exchangeSvc', () ->
	exchanges:
		mtGox: # apiDoc: 'https://bitbucket.org/nitrous/mtgox-api'
			name: 'Mt. Gox',
			currency: '$',
			site: 'https://mtgox.com/',
			url: 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

angular.module('app').factory 'tickerSvc', (exchangeSvc) ->
	return

angular.module('app').factory 'socket', (socketFactory) ->
	socketFactory({
		ioSocket: io.connect 'http://socketio.mtgox.com:80/mtgox?Currency=USD'
	})

angular.module('app').controller 'AppCtrl', (socket) ->
	socket.on 'message', (data) ->
		console.log(data)

	return