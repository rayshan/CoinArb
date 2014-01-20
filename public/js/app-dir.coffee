angular.module('app').directive 'caNumDisplay', ($animate) ->
	templateUrl: 'partials/ca-num-display.html'
	replace: true
	restrict: 'E'
	scope: # isolated scope for type only
		name: "@" # bind string
		type: "@"
		cur: "=" # bind scope var
		pre: "="
		baseline: "="
		baselineBest: "="
		curId: "="
		curBaseline: "="
		preBaseline: "="
	link: (scope, ele, attrs) ->
		_numEle = angular.element(ele[0].querySelector('.ca-main'))

		scope.getBaselineNameEng = () ->
			scope.$parent.app.data[scope.baseline].displayNameEng if scope.baseline?

		scope.show = (input, equality) ->
			!isNaN(parseFloat(input)) and isFinite(input) and Math.abs(input) > equality # only show when > 0.009%

		scope.diff = (cur, pre, pct) ->
			if pct == true then (cur - pre) / pre * 100 else cur - pre

		scope.diffBaseline = (input, baseline) ->
			Math.abs(input - baseline) if input? and baseline?

		scope.$on 'tickerUpdate', () ->
			if scope.cur != scope.pre and scope.show(scope.diff(scope.cur, scope.pre, true), 0.009)
				c = 'change'
				$animate.addClass(_numEle, c, () ->
					$animate.removeClass(_numEle, c)
				)
			return

		return

angular.module('app').directive 'caChart', ($q) ->
	templateUrl: 'partials/ca-chart.html'
	restrict: 'E'
	scope:
		data: "="
	link: (scope, ele, attrs) ->
		scope.dataLoaded = false
		scope.chartProcessed = false




		w = 500
		h = 100 # %

		scalerX = d3.scale.ordinal()
				.rangeRoundBands([0, w], .5, .1) # interval, padding, outerPadding, 0~1, 0.5 = band width = padding width
		scalerY = d3.scale.linear()
				.range([h, 0]) # %

		chart = d3.select(".ca-chart-line")
				.attr("width", w)
				.attr("height", "#{h}%")

		successCb = (data) ->
			scope.dataLoaded = true

			max = d3.max(data, (d) -> d.frequency) # d = row data, i = index
			scalerX.domain(data.map((d) -> d.letter))
			scalerY.domain([0, max])

			bar = chart.selectAll("g")
					.data(data)
					.enter().append("g")
						.attr("transform", (d, i) -> "translate(#{scalerX(d.letter)}, 0)") # translate x, y

			bar.append("rect")
					.attr("y", (d) -> "#{scalerY(d.frequency)}%")
					.attr("height", (d) -> "#{h - scalerY(d.frequency)}%") # calc(vw - px) doesnt work in safari
					.attr("width", scalerX.rangeBand())

			bar.append("text")
					.attr("x", scalerX.rangeBand() / 2)
					.attr("y", (d) -> "#{scalerY(d.frequency) - 5}%")
					.attr("dy", ".75em")
					.text((d) -> d.letter)

			return

		errorCb = (what) ->
			console.log(what)
			return

		notifyCb = (what) ->
			console.log(what)
			return

		forceNum = (d) ->
			d.frequency = +d.frequency
			d

		d3tsv = (uri) ->
			deferred = $q.defer()
			d3.tsv uri, forceNum, (err, data) ->
#				deferred.notify "working..."
				if err?
					deferred.reject "didn't work"
				else
					deferred.resolve data
				return
			deferred.promise

		promise = d3tsv(scope.data)
		promise.then(successCb, errorCb, notifyCb)

		return