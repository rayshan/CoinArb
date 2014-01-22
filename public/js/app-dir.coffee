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

angular.module('app').directive 'caChart', ($q, $filter) ->
	templateUrl: 'partials/ca-chart.html'
	restrict: 'E'
	scope:
		data: "="
	link: (scope, ele, attrs) ->
		scope.dataLoaded = false
		scope.chartProcessed = false

		# ===========================
		# render things while data loads

		chartCanvas = ele[0].querySelector(".ca-chart-line").children[0]

		wOrig = d3.select(chartCanvas).node().offsetWidth
		hOrig = d3.select(chartCanvas).node().offsetHeight
#		hOrig = 300
#		console.log(wOrig, hOrig)
		# offsetW/H = border + padding + vertical scrollbar (if present & rendered) + CSS width
		margin =
			t: 0
			r: 50
			b: 100
			l: 50
		margin2 =
			t: 250
			r: 50
			b: 20
			l: 50
		w = wOrig - margin.l - margin.r
		h = hOrig - margin.t - margin.b
		h2 = hOrig - margin2.t - margin2.b

		color = d3.scale.category10() # 20 avail

		x = d3.time.scale().range([0, w])
		x2 = d3.time.scale().range([0, w])
		y = d3.scale.linear().range([h, 0])
		y2 = d3.scale.linear().range([h2, 0])

		axisX = d3.svg.axis().scale(x).orient("bottom")
		axisX2 = d3.svg.axis().scale(x2).orient("bottom")
		axisY = d3.svg.axis()
				.scale(y)
				.orient("left")
				.ticks(10, "$")

		line = d3.svg.line()
				.interpolate("basis")
				.x((d) -> x(d.date))
				.y((d) -> y(d.close))
		line2 = d3.svg.line()
				.interpolate("basis")
				.x((d) -> x2(d.date))
				.y((d) -> y2(d.close))

		brushed = () ->
			x.domain(if brush.empty() then x2.domain() else brush.extent())
			#			y.domain(if brush.empty() then y2.domain() else brush.extent())
			focus.selectAll("path.line").attr("d", (d) -> line(d.values))
			focus.select(".x1").call(axisX)
#			focus.select(".y1").call(axisY)
			return
		brush = d3.svg.brush().x(x2).on("brush", brushed)

		chart = d3.select(chartCanvas)
				.attr("width", w + margin.l + margin.r)
				.attr("height", h + margin.t + margin.b)

		chart.append("defs").append("clipPath") # defining for later reuse
				.attr("id", "focus-clip")
			.append("rect")
				.attr("width", w)
				.attr("height", h)

		focus = chart.append("g")
				.attr('id', 'focus')
				.attr("transform", "translate(#{ margin.l }, #{ margin.t })")

		context = chart.append("g")
				.attr('id', 'context')
				.attr("transform", "translate(#{ margin2.l }, #{ margin2.t })")

		infoBox = chart.append("g")
				.attr('id', 'info-box')
				.attr("transform", "translate(#{ margin.l * 2 }, 0)")

		renderCb = (resolved) ->
			_data = resolved.data
			_startTimeData = resolved.startTimeData
			_startTimeChart = moment()

			scope.dataLoaded = true
			_dataLoadT = moment.duration(_startTimeChart.diff(_startTimeData), 'ms').asSeconds()

			# ===========================
			# render all

			color.domain(d3.keys(_data[0]).filter((key) -> key is "exchange"))

			_dataNested = d3.nest().key((d) -> d.exchange).entries(_data)

			xMin = d3.min(_dataNested, (d) -> d3.min(d.values, (d) -> d.date))
			xMax = d3.max(_dataNested, (d) -> d3.max(d.values, (d) -> d.date))
			yMax = d3.max(_dataNested, (d) -> d3.max(d.values, (d) -> d.close))
			x.domain([xMin, xMax])
			y.domain([0, yMax])
			x2.domain(x.domain())
			y2.domain(y.domain())

			focus.append("g")
					.attr("class", "axis x1")
					.attr("transform", "translate(0, #{ h })")
					.call(axisX)

			focus.append("g")
					.attr("class", "axis y1")
					.call(axisY)
				.append("text")
					.attr("class", "axis label")
					.attr("transform", "rotate(-90)")
					.attr("y", 6)
					.attr("dy", "1em") # shift along y axis
					.text("per Bitcoin")

			focusExchanges = focus.selectAll(".exchange")
					.data(_dataNested, (d) -> d.key)
				.enter().append("g")
					.attr("clip-path", "url(#focus-clip)")
					.attr("class", "exchange")

			focusExchanges.append("path")
					.attr("d", (d) -> line(d.values))
				.attr("class", "line")
					.style("stroke", (d) -> color(d.key))

			# ============================

			context.append("g")
					.attr("class", "axis x2")
					.attr("transform", "translate(0, #{ h2 })")
					.call(axisX2)

			context.append("g")
					.attr("class", "x brush")
					.call(brush)
				.selectAll("rect")
					.attr("y", -6)
					.attr("height", h2 + 7)

			contextExchanges = context.selectAll(".exchange")
					.data(_dataNested, (d) -> d.key)
				.enter().append("g")
					.attr("class", "exchange")

			contextExchanges.append("path")
					.attr("class", "line")
					.attr("d", (d) -> line2(d.values))
					.style("stroke", (d) -> color(d.key))

			# ============================

#			legend = chart.append("g")
#			.attr("class", "legend")
#			.attr("height", 100)
#			.attr("width", 100)
#			.attr("transform", "translate(-20,50)")
#
#			legendRect = legend.selectAll("rect").data(color)
#
#			legendRect.enter()
#			.append("rect")
#			.attr("x", w - 65)
#			.attr("width", 10)
#			.attr("height", 10)
#			.attr("y",(d, i) -> i * 20)
#			.style("fill", (d) -> d[1])
#
#			legendText = legend.selectAll("text").data(color)
#
#			legendText.enter().append("text")
#			.attr("x", w - 52)
#			.attr("y",(d, i) -> i * 20 + 9)
#			.text((d) -> d[0])

			# ============================

			scope.chartProcessed = true
			_chartProcessT = moment.duration(moment().diff(_startTimeChart), 'ms').asSeconds()
			_tTotal = $filter("round")(_dataLoadT + _chartProcessT)

			infoBox.append("text")
					.attr("dy", "1em") # shift along y axis from top
					.text("Generated by CoinArb in #{ _tTotal } s.")

			return

		errorCb = (what) ->
			console.log(what.msg)
			console.log(what.error)
			return

		notifyCb = (what) ->
			console.log(what)
			return

		dataParser = (d) ->
			d.date = d3.time.format("%m/%d/%y").parse(d.date) # %x doesn't work b/c uses %Y which has century previx
			d.high = +d.high
			d.low = +d.low
			d.close = +d.close
			d.volume = +d.volume
			d

		d3LoadData = (uri) ->
			_startTimeData = moment()
			deferred = $q.defer()
			d3.tsv uri, dataParser, (err, data) ->
#				deferred.notify "working..."
				if err?
					deferred.reject {msg: "didn't work", error: err, startTimeData: _startTimeData}
				else
					deferred.resolve {msg: "worked", data: data, startTimeData: _startTimeData}
				return
			deferred.promise

		promise = d3LoadData(scope.data)
		promise.then(renderCb, errorCb, notifyCb)

		return