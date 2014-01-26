dir = angular.module('CaAppDir', [
	'ngAnimate'
])

dir.directive 'caNumDisplay', ($animate) ->
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

		scope.getBaselineNameEng = ->
			scope.$parent.app.data[scope.baseline].displayNameEng if scope.baseline?

		scope.show = (input, equality) ->
			!isNaN(parseFloat(input)) and isFinite(input) and Math.abs(input) > equality # only show when > 0.009%

		scope.diff = (cur, pre, pct) ->
			if pct == true then (cur - pre) / pre * 100 else cur - pre

		scope.diffBaseline = (input, baseline) ->
			Math.abs(input - baseline) if input? and baseline?

		scope.$on 'tickerUpdate', ->
			if scope.cur != scope.pre and scope.show(scope.diff(scope.cur, scope.pre, true), 0.009)
				c = 'change'
				$animate.addClass(_numEle, c, ->
					$animate.removeClass(_numEle, c)
				)
			return

		return

dir.directive 'caChart', ($q, $filter, caD3Svc) ->
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

		brushed = ->
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

		legend = ->
			# `this` should be classed legend, = current node wrapped by d3
			items = {}

			chart = d3.select(@.node().parentNode) # select parent chart

			lPadding = @.attr("data-style-padding") or 5

			lBox = @.selectAll(".box").data([true])
			lItems = @.selectAll(".items").data([true])

			lBox.enter().append("rect").classed "box", true # .class true assigns class
			lItems.enter().append("g").classed "items", true

			chart.selectAll("[data-legend]").each ->
				# css selector of all paths w/ attr named data-legend using brackets; data- is html5 standard; this = path
				path = d3.select(@)

				# returns .attr that's the name of series of the only element; b/c 2nd arg == null
				items[path.attr("data-legend")] =
					pos: path.attr("data-legend-pos") or @getBBox().y
					# getBBox() is w3 svg spec, gets bounding box of path, .y sorts by whatever has highest max value
					color:
						path.attr("data-legend-color") || if path.style("fill") isnt "none" then path.style("fill") else path.style("stroke")
				return

			items = d3.entries(items).sort((a, b) -> a.value.pos - b.value.pos)
			# array.sort compare function takes 1st & 2nd, then 2nd & 3rd... if compare function returns
			# < 0 a before b
			# == 0 order unchanged
			# > 0 b before a

			lItems.selectAll("text")
					.data(items, (d) -> d.key)
					.call((d) -> d.enter().append "text")
					.call((d) -> d.exit().remove())
					.attr("y", (d, i) -> i + "em")
					.attr("x", "1em")
					.text((d) -> d.key)

			lItems.selectAll("circle")
					.data(items, (d) -> d.key)
					.call((d) -> d.enter().append "circle")
					.call((d) -> d.exit().remove())
					.attr("cy", (d, i) -> i - 0.25 + "em")
					.attr("cx", 0)
					.attr("r", "0.4em")
					.style("fill", (d) -> d.value.color)

			return

		renderCb = (resolved) ->
			_startTimeData = resolved.startTimeData
			_startTimeChart = moment()

			scope.dataLoaded = true
			_dataLoadT = moment.duration(_startTimeChart.diff(_startTimeData), 'ms').asSeconds()

			# ===========================
			# render all

			exchanges = Object.keys(d3.nest()
					.key((d) -> d.exchange)
					.rollup((leaves) -> return null) # just need to roll up, has to specify a f()
					.map(resolved.data))

			# color.domain(d3.keys(_data[0]).filter((key) -> key is "exchange")) # just returns ['exchange'], not sure what for
			color.domain(exchanges)
			# color domain optional but a good idea for deterministic behavior, as inferring the domain from usage will be dependent on ordering

			_dataNested = d3.nest()
					.key((d) -> d.exchange) # group by this key
					.entries(resolved.data) # apply to this data

			xMin = d3.min(_dataNested, (d) -> d3.min(d.values, (d) -> d.date))
			xMax = d3.max(_dataNested, (d) -> d3.max(d.values, (d) -> d.date))
			yMax = d3.max(_dataNested, (d) -> d3.max(d.values, (d) -> d.close))
			x.domain([xMin, xMax])
			y.domain([0, yMax])
			x2.domain(x.domain())
			y2.domain(y.domain())

			# render x axis
			focus.append("g")
					.attr("class", "axis x1")
					.attr("transform", "translate(0, #{ h })")
					.call(axisX)

			# render y axis
			focus.append("g")
					.attr("class", "axis y1")
					.call(axisY)
				.append("text")
					.attr("class", "axis label")
					.attr("transform", "rotate(-90)")
					.attr("y", 6)
					.attr("dy", "1em") # shift along y axis
					.text("per Bitcoin")

			# render clip path & g for lines
			focusExchanges = focus.selectAll(".exchange")
					.data(_dataNested, (d) -> d.key)
				.enter().append("g")
					.attr("clip-path", "url(#focus-clip)")
					.attr("class", "exchange")

			# render lines
			focusExchanges.append("path")
					.attr("d", (d) -> line(d.values))
					.attr("data-legend", (d) -> d.key) # add this attr for legend f() to render legend
					.attr("class", "line focus") # focus:hover changes stroke-width
					.style("stroke", (d) -> color(d.key))

			# render legend
			focus.append("g")
					.attr("class", "legend")
					.attr("transform", "translate(50,30)")
					.style("font-size", "12px")
					.call(legend)

			# ============================

			# render x axis
			context.append("g")
					.attr("class", "axis x2")
					.attr("transform", "translate(0, #{ h2 })")
					.call(axisX2)

			# render y axis
			context.append("g")
					.attr("class", "x brush")
					.call(brush)
				.selectAll("rect")
					.attr("y", -6)
					.attr("height", h2 + 7)

			# render g for lines
			contextExchanges = context.selectAll(".exchange")
					.data(_dataNested, (d) -> d.key)
				.enter().append("g")
					.attr("class", "exchange")

			# render lines
			contextExchanges.append("path")
					.attr("class", "line")
					.attr("d", (d) -> line2(d.values))
					.style("stroke", (d) -> color(d.key))

			# ============================

			scope.chartProcessed = true
			_chartProcessT = moment.duration(moment().diff(_startTimeChart), 'ms').asSeconds()
			_tTotal = $filter("round")(_dataLoadT + _chartProcessT)

			infoBox.append("text")
					.attr("dy", "1em") # shift along y axis from top
					.text("Generated by CoinArb in #{ _tTotal } s.")

			return

		errorCb = (what) -> console.log what.msg, what.error; return

		notifyCb = (what) -> console.log what; return

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

dir.directive 'caSelectFocus', ($q, $filter) ->
	#	with copy to clipboard button
	return