angular.module('app', [
	'ngResource'
	'ngAnimate'
	'btford.socket-io'
	'poller'
])

angular.module('app').run (tickerSvc) ->
	# excute immediately on app bootstrap
	return

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
		now = moment()
#		console.log("#{id} processed at #{now.format('h:mm:ss a')}")
		data = exchangeSvc.data[id].fetched

		if data.initialized is false
			data.initialized = true

			current.updateTime = now
			data.current = {}
			angular.copy(current, data.current)

			if notificationSvc.enabled
				notificationSvc.create(exchangeSvc.data[id].fetched.current.last)

			# $rootScope.$broadcast("#{id}Update")
			$rootScope.$broadcast("tickerUpdate")
		else
			changed = current.last != data.current.last or current.spread != data.current.spread
			if changed
				current.updateTime = now
				data.previous = {} if !data.previous?
				angular.copy(data.current, data.previous)
				angular.copy(current, data.current)

				if notificationSvc.enabled
					notificationSvc.create(exchangeSvc.data[id].fetched.current.last)

				# $rootScope.$broadcast("#{id}Update")
				$rootScope.$broadcast("tickerUpdate")

		return

angular.module('app').factory 'tickerSvc', ($resource, $filter, poller, socketSvc, exchangeSvc, checkAndCopySvc) ->
	USDCNY = 6.05
	pollers = []

	callback = (id) ->
		(res) ->
			switch id
				when "btcchina"
					current =
						spread: $filter('round')((res.ticker.buy - res.ticker.sell) / USDCNY)
						last: $filter('round')(res.ticker.last / USDCNY)
						updateTime: null
#						error: null
					checkAndCopySvc.process(id, current)
				else # all bitcoinaverage api
					current =
						spread: $filter('round')(res[id].rates.bid - res[id].rates.ask)
						last: $filter('round')(res[id].rates.last)
						updateTime: null
#						error: null
					checkAndCopySvc.process(id, current)

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
		else socketSvc.process(data)

	for poller in pollers
		poller.item.promise.then(null, null, callback(poller.id))

	return

angular.module('app').factory 'socketSvc', ($rootScope, $filter, socketFactory, checkAndCopySvc) ->
	unsubscribe =
		depthBTCUSD:
			op: 'unsubscribe'
			channel: '24e67e0d-1cad-4cc0-9e7a-f8523ef460fe'
		tradeBTC:
			op: 'unsubscribe'
			channel: 'dbf1dee9-4f2e-4a08-8cb7-748919a71b21'

	process: (data) ->
		socket = socketFactory({
			ioSocket: io.connect data.api.uri
		# ioSocket: io.connect 'https://socketio.mtgox.com:443/mtgox?Currency=USD', {secure: true}
		})

#		socket.on 'connect', () ->
#			return

		for channel, obj of unsubscribe
			socket.send(JSON.stringify(obj))

		socket.on 'message', (res) ->
			if res.op.indexOf("subscribe") == -1 and res.channel_name.indexOf("ticker") != -1 # no subscribe / yes ticker
				current =
					spread: $filter('round')(res.ticker.buy.value - res.ticker.sell.value)
					last: $filter('round')(res.ticker.last.value)
					# last_local is the last trade in your selected auxiliary currency
					# last_orig is the last trade (any currency)
					# last_all is that last trade converted to the auxiliary currency
					# last is the same as last_local
					updateTime: null
					error: null
				checkAndCopySvc.process(data.id, current)
			return

		return

angular.module('app').controller 'AppCtrl', ($scope, exchangeSvc) ->
	@data = exchangeSvc.data
	@showCount = () ->
		count = 0
		for exchange, data of @data
			if data.show is true
				count++
		count

	@cols = 12 / @showCount() # must be divisible
	@baseline = "mtgox"
	@currency = "USD"

	@hide = (id) ->
		if @showCount() > 1
			@data[id].show = false
			@cols = 12 / @showCount()
		else throw "Must have at least 1 exchange in display."
		return

	$scope.$on "tickerUpdate", () =>
		@data = exchangeSvc.data
#		console.log(@data.mtgox.fetched.current.last)
		return

	return