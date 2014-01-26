angular.module('CaApp', [
	'ngResource'
	'ngAnimate'
	'btford.socket-io'
	'poller'
])

angular.module('CaApp').run (caTickerSvc) ->
	# excute immediately on app bootstrap
	return

angular.module('CaApp').controller 'CaAppCtrl', ($scope, $interval, exchangeSvc) ->
	@getTime = (timeZone) -> now = moment(); now.format('HH:mm:ss')

	@showTime = () ->
		true
#		now = moment()
#		now.second() % 2 is 0

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
	@currency = "USD"

	@baseline = "mtgox"
	@baselineBest = null
	@setBaseline = (id) -> @baseline = id; $scope.$broadcast "baselineSet"; return
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