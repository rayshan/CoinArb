app = angular.module('CaApp', [
	'CaAppDir'
	'CaAppSvc'
	'CaAppFilter'
	'CaChartModule'
])

app.run (caTickerSvc) ->
	# excute immediately on app bootstrap
	return

app.controller 'CaAppCtrl', ($scope, $interval, exchangeSvc) ->
	@showExchanges = true
	@showChart = true
	@currency = "USD"

	@getTime = (timeZone) -> now = moment(); now.format('HH:mm:ss')
	$interval @getTime, 1

	@data = exchangeSvc.data
	@dataChart = "data/data.tsv"

	@showCount = () ->
		count = 0
		for exchange, data of @data
			if data.show is true
				count++
		count
	@cols = 12 / @showCount() # must be divisible

	@baseline = "mtgox"
	@baselineBest = null
	@setBaseline = (id) -> @baseline = id; $scope.$broadcast "baselineSet", @baseline; return
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

	$scope.$on "tickerUpdate", () => @data = exchangeSvc.data; @getBaselineBest(); return

	$scope.$on "baselineSet", () => @getBaselineBest(); return

	return