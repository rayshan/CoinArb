angular.module('app', [
	'ngResource'
	'ngAnimate'
	'btford.socket-io'
	'poller'
])

angular.module('app').run (caTickerSvc) ->
	# excute immediately on app bootstrap
	return

angular.module('app').factory 'caNotificationSvc', () ->
	enabled: false
	create:
		(data) ->
			if Notification.permission != 'granted'
				Notification.requestPermission()

			n = new Notification 'yo', {
				body: data
			}
			return

angular.module('app').factory 'caCheckAndCopySvc', ($rootScope, exchangeSvc, caNotificationSvc) ->
	process: (id, current) ->
		now = moment()
		data = exchangeSvc.data[id].fetched

		if data.initialized is false
			data.initialized = true

			current.updateTime = now
			data.current = {}
			angular.copy(current, data.current)

			if caNotificationSvc.enabled
				caNotificationSvc.create(exchangeSvc.data[id].fetched.current.last)

			# $rootScope.$broadcast("#{id}Update")
			$rootScope.$broadcast("tickerUpdate")
		else
			changed = current.last != data.current.last or current.spread != data.current.spread
			if changed
				current.updateTime = now
				data.previous = {} if !data.previous?
				angular.copy(data.current, data.previous)
				angular.copy(current, data.current)

				if caNotificationSvc.enabled
					caNotificationSvc.create(exchangeSvc.data[id].fetched.current.last)

				# $rootScope.$broadcast("#{id}Update")
				$rootScope.$broadcast("tickerUpdate")

		return

angular.module('app').factory 'caTickerSvc', ($resource, $filter, poller, caSocketSvc, exchangeSvc, caCheckAndCopySvc) ->
	USDCNY = 6.05
	pollers = []

	notifyCb = (id) ->
		(res) ->
			switch id
				when "btcchina"
					current =
						last: $filter('round')(res.ticker.last / USDCNY)
						spread: $filter('round')((res.ticker.buy - res.ticker.sell) / USDCNY)
					#						error: null
					caCheckAndCopySvc.process(id, current)
#				when "btce"
#					current =
#						last: $filter('round')(res.ticker.last)
#						spread: $filter('round')(res.ticker.buy - res.ticker.sell)
#					#						error: null
#					caCheckAndCopySvc.process(id, current)
				else # all bitcoinaverage api
					current =
						last: $filter('round')(res[id].rates.last)
						spread: $filter('round')(res[id].rates.bid - res[id].rates.ask)
					#						error: null
					caCheckAndCopySvc.process(id, current)
			return

	errorCb = (reason) ->
		throw "poller or resource failed"
		console.log(reason)
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
		else caSocketSvc.process(data)

	for poller in pollers
		poller.item.promise.then(null, errorCb, notifyCb(poller.id))

	return

angular.module('app').factory 'caSocketSvc', ($rootScope, $filter, socketFactory, caCheckAndCopySvc) ->
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

		socket.forward('error')

#		socket.on 'connect', () ->
#			return

		for channel, obj of unsubscribe
			socket.send(JSON.stringify(obj))

		socket.on "message", (res) ->
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
				caCheckAndCopySvc.process(data.id, current)
			return

		socket.on "socket:error", (event, data) ->
			throw "socket failed"
			console.log(event)
			console.log(data)
			return

		return

angular.module('app').controller 'CaAppCtrl', ($scope, $timeout, exchangeSvc) ->
#	fireDigestEverySecond = () ->
#		$timeout fireDigestEverySecond , 3000
#		return
#
#	fireDigestEverySecond()
#
#	@getTime = (timeZone) ->
#		now = moment()
#		now.format('h:mm:ss a')
#
#	@showTime = () ->
#		now = moment()
#		now.second() % 2 is 0

	@data = exchangeSvc.data
	@dataChart = "data/data.tsv"

	@showCount = () ->
		count = 0
		for exchange, data of @data
			if data.show is true
				count++
		count

	@cols = 12 / @showCount() # must be divisible
	@currency = "USD"

	@baseline = "mtgox"
	@baselineBest = null
	@setBaseline = (id) ->
		@baseline = id
		$scope.$broadcast "baselineSet"
		return
	@getBaselineBest = () ->
		_lasts = []
		_highest = null
		_best = null
		for exchange of @data
			_lasts[exchange] = @data[exchange].fetched.current.last if @data[exchange].fetched.current?
		for key, value of _lasts
			if @data[@baseline].fetched.current?
				baselineDiff = Math.abs(value - @data[@baseline].fetched.current.last)
				if !_highest? or baselineDiff > _highest
					_highest = baselineDiff
					_best = key
		@baselineBest = _best
		return

	@hide = (id) ->
		if @showCount() > 1
			@data[id].show = false
			@cols = 12 / @showCount()
		else throw "Must have at least 1 exchange in display."
		return

	$scope.$on "tickerUpdate", () =>
		@data = exchangeSvc.data
		@getBaselineBest()
		return

	$scope.$on "baselineSet", () =>
		@getBaselineBest()
		return

	return