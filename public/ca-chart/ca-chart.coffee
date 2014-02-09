module = angular.module('CaChartModule', [])

module.factory 'caD3Svc', ($q, $filter) ->
	chartData = null
	chartObj = null
	time =
		preRender: null
		fetch: null
		render: null

	dateParser = (input) -> d3.time.format("%m/%d/%y").parse(input)
	dataParser = (d) ->
		d.date = dateParser(d.date) # %x doesn't work b/c uses %Y which has century prefix
		d.high = +d.high
		d.low = +d.low
		d.close = +d.close
		d.volume = +d.volume
		d
	dataTransform = (data, baseline, field) ->
		# pull basline values out
		chartData.some((exchange) -> exchange.key is baseline && baseline = exchange.values)

		# build date / value index for quick lookups
		baseline = baseline.reduce((output, item) ->
			output[item.date] = item[field]
			output
		, {})

		# add delta field to each data point
		chartData.forEach((item) ->
			item.values.forEach((valItem) ->
				bl = baseline[valItem.date]
				val = valItem[field]
				valItem.delta = if bl? then (if bl is val then 0 else val / bl - 1) else null
				return
			); return
		); return

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
				color: path.attr("data-legend-color") || if path.style("fill") isnt "none" then path.style("fill") else path.style("stroke")
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

	preRender: (ele) ->
		_startT = moment()
		_deferred = $q.defer()

		transitionDuration = 250

		canvas = ele[0].querySelector(".ca-chart-line").children[1] # 0 is buttons div

		# update = -> canvas.transition().duration(transitionDuration).call(c)

		# positioning & sizing
		wOrig = d3.select(canvas).node().offsetWidth
		hOrig = d3.select(canvas).node().offsetHeight
		# offsetW / H = border + padding + vertical scrollbar (if present & rendered) + CSS width
		marginBase = 55 # for multipliers
		marginFocus =
			t: marginBase / 3
			l: marginBase, r: marginBase / 3
			b: hOrig * .4
		marginContext =
			t: hOrig * .6 + marginBase / 2
			l: marginBase, r: marginBase / 3
			b: marginBase * .4
		w = wOrig - marginFocus.l - marginFocus.r
		hFocus = hOrig - marginFocus.t - marginFocus.b
		hContext = hOrig - marginContext.t - marginContext.b

		# scales
		color = d3.scale.category10()
		xFocus = d3.time.scale().range([0, w])
		xContext = d3.time.scale().range([0, w])
		yFocus = d3.scale.linear().range([hFocus, 0])
		yContext = d3.scale.linear().range([hContext, 0])

		# axis
		axisXFocus = d3.svg.axis().scale(xFocus).orient("bottom")
		axisXContext = d3.svg.axis().scale(xContext).orient("bottom") # different for brushing
		axisY = (chartType) -> # only 1 b/c context has no y axis
			d3.svg.axis().scale(yFocus).orient "left"
					.ticks(10, if chartType is "absolute" then "$" else "+%")

		# line rendering f, 1 for focus, 1 for context
		lineFocus = d3.svg.line()
				.interpolate("basis")
				.x (d) -> xFocus d.date
				.y (d) -> yFocus d.close
		lineContext = d3.svg.line()
				.interpolate "basis"
				.x (d) -> xContext d.date
				.y (d) -> yContext d.close
		lineDelta = d3.svg.line()
				.interpolate "basis"
				.x (d) -> xFocus d.date
				.y (d) -> yFocus d.delta

		chart = d3.select(canvas)
				.attr("width", w + marginFocus.l + marginFocus.r)
				.attr("height", hFocus + marginFocus.t + marginFocus.b)

		chart.append("defs").append("clipPath") # defining for later reuse
				.attr("id", "focus-clip")
				.append("rect")
				.attr("width", w)
				.attr("height", hFocus)

		focus = chart.append("g")
				.attr('id', 'focus')
				.attr("transform", "translate(#{ marginFocus.l }, #{ marginFocus.t })")

		context = chart.append("g")
				.attr('id', 'context')
				.attr("transform", "translate(#{ marginContext.l }, #{ marginContext.t })")

		infoBox = chart.append("g")
				.attr('id', 'info-box')
				.attr("transform", "translate(#{ marginFocus.l * 2 }, 0)")

		# expose only things needed by render
		chartObj =
			transitionDuration: transitionDuration
			hFocus: hFocus
			hContext: hContext
			xFocus: xFocus
			xContext: xContext
			yFocus: yFocus
			yContext: yContext
			axisXFocus: axisXFocus
			axisXContext: axisXContext
			axisY: axisY
			lineFocus: lineFocus
			lineContext: lineContext
			lineDelta: lineDelta
			color: color
			focus: focus
			context: context
			infoBox: infoBox

		time.preRender = moment.duration(moment().diff(_startT), 'ms').asSeconds()

		_deferred.resolve {msg: "pre-rendered"}; _deferred.promise

	fetch: (uri) -> # incl. data transform
		_startT = moment()
		_deferred = $q.defer()

		d3.tsv uri, dataParser, (err, data) ->
			# deferred.notify "working..."
			if err?
				_deferred.reject {msg: "fetching failed", error: err}
			else
				chartData = d3.nest()
						.key((d) -> d.exchange) # group by this key
						.entries(data) # apply to this data

				time.fetch = moment.duration(moment().diff(_startT), 'ms').asSeconds()
				_deferred.resolve {msg: "fetched"}
			return
		_deferred.promise

	render: (chartType, brushExtentInit) ->
		(resolve) ->
			c = chartObj

			_deferred = $q.defer()
			_startT = moment()

			# brush
			c.brushed = ->
				c.xFocus.domain(if c.brush.empty() then c.xContext.domain() else c.brush.extent())
				#			yMax = d3.max(chartData, (d) -> d3.max(d.values, (d) -> d.close))
				#			c.yFocus.domain([0, yMax])
				#			c.yFocus.domain(if c.brush.empty() then c.yFocus.domain() else c.brush.extent())
				c.focus.selectAll("path.line").attr("d", (d) -> c.lineFocus(d.values))
				c.focus.select(".xFocus").call(c.axisXFocus)
				#			c.focus.select(".yFocus").call(c.axisY)
				return
			c.brush = d3.svg.brush()
					.x(c.xContext)
					.on("brush", c.brushed) # .x only so don't brush y axis

			# ===========================
			# render all

			# color.domain(d3.keys(_data[0]).filter((key) -> key is "exchange")) # just returns ['exchange'], not sure what for
			c.color.domain(chartData.map((d) -> return d.key))
			# color domain optional but a good idea for deterministic behavior
			# as inferring the domain from usage will be dependent on ordering

			xMin = d3.min(chartData, (d) -> d3.min(d.values, (d) -> d.date))
			xMax = d3.max(chartData, (d) -> d3.max(d.values, (d) -> d.date))
			yMin = if chartType is "absolute" then 0 else d3.min(chartData, (d) -> d3.min(d.values, (d) -> d.delta))
			yMax = d3.max(chartData, (d) -> d3.max(d.values, (d) ->
				if chartType is "absolute" then d.close else d.delta))
			c.xFocus.domain([xMin, xMax])
			c.yFocus.domain([yMin, yMax])
			c.xContext.domain(c.xFocus.domain())
			c.yContext.domain(c.yFocus.domain())

			# render x axis
			c.focus.append("g")
					.attr "class", "axis xFocus"
					.attr "transform", "translate(0, #{ c.hFocus })"
					.call c.axisXFocus

			# render y axis
			axisYObj = c.focus.select(".axis.yFocus")
			if axisYObj.empty()
				c.focus.append("g")
						.attr "class", "axis yFocus"
						.call c.axisY(chartType)
					.append "text"
						.attr "class", "axis label"
						.attr "transform", "rotate(-90)"
						.attr "y", 6
						.attr "dy", "1em" # shift along y axis
						.text "per Bitcoin"
			else axisYObj.transition().duration(c.transitionDuration).call(c.axisY(chartType))

			# render clip path & g for lines
			focusExchanges = c.focus.selectAll ".exchange"
					.data chartData, (d) -> d.key
				.enter().append "g"
					.attr "clip-path", "url(#focus-clip)"
					.attr "class", "exchange"

			# render lines
			focusPaths = c.focus.selectAll(".line.focus")
			if focusPaths.empty()
				focusExchanges.append("path")
						.attr "d", (d) -> c.lineFocus(d.values)
						.attr("data-legend", (d) -> d.key) # add this attr for legend f() to render legend
						.attr("class", "line focus") # focus:hover changes stroke-width
						.style("stroke", (d) -> c.color(d.key))
			else
				focusPaths
						.transition().duration(c.transitionDuration)
						.attr "d", (d) -> if chartType is "absolute" then c.lineFocus(d.values) else c.lineDelta(d.values)

			# render legend
			c.focus.append("g")
					.attr("class", "legend")
					.attr("transform", "translate(50,30)")
					.style("font-size", "12px")
					.call(legend)

			# ============================

			# render x axis
			c.context.append("g")
					.attr("class", "axis xContext")
					.attr("transform", "translate(0, #{ c.hContext })")
					.call(c.axisXContext)

			# render brush
			c.context.append("g")
					.attr("class", "brush")
					.call(c.brush)
				.selectAll("rect")
					.attr("y", -6)
					.attr("height", c.hContext + 7)

			# render g for lines
			contextExchanges = c.context.selectAll(".exchange")
					.data(chartData, (d) -> d.key)
					.enter().append("g")
					.attr("class", "exchange")

			# render lines
			contextExchanges.append("path")
					.attr("class", "line")
					.attr("d", (d) -> c.lineContext(d.values))
					.style("stroke", (d) -> c.color(d.key))

			# ============================

			# render initial brush
#			if brushExtentInit?
#				brushExtentInit.forEach (item, i, arr) -> arr[i] = dateParser(item); return
#				c.context.select '.brush'
#						.call c.brush.extent(brushExtentInit) # set brushed area
#						.call c.brushed # calc brush

			# ============================

			time.render = moment.duration(moment().diff(_startT), 'ms').asSeconds()
			_deferred.resolve(); _deferred.promise

	renderInfoBox: ->
		_totalT = 0
		_totalT += time[t] for t of time
		chartObj.infoBox.append("text")
				.attr("dy", "1em") # shift along y axis from top
				.text("Generated by CoinArb in #{ $filter("round")(_totalT) } s.")
		return

	transform: dataTransform
	chartData: -> chartData # = chartData doesn't work
	chartObj: -> chartObj

module.directive 'caChart', ($q, $filter, caD3Svc) ->
	templateUrl: 'ca-chart/ca-chart.html'
	restrict: 'E'
	scope:
		data: "="
	link: (scope, ele) ->
		scope.rendered = false
		scope.brushExtentInit = ["10/1/13", "1/15/14"]
		scope.baseline = scope.$parent.app.baseline
		scope.$on "baselineSet", (event, baseline) -> scope.baseline = baseline; return

		preRenderP = caD3Svc.preRender(ele)
		fetchP = caD3Svc.fetch(scope.data)

		errorCb = (what) -> console.log what; return
		notifyCb = (what) -> console.log what; return

		$q.all([preRenderP, fetchP])
				.then(caD3Svc.render("absolute", scope.brushExtentInit), errorCb, notifyCb)
				.then( ->
						caD3Svc.renderInfoBox()
						scope.rendered = true
						scope.c = caD3Svc.chartObj()
						scope.data = caD3Svc.chartData()
						return)

		scope.update = (chartType) ->
			if chartType is "absolute"
				caD3Svc.render("absolute", scope.brushExtentInit)()
			else
				caD3Svc.transform(scope.data, scope.baseline, "close")
				caD3Svc.render("relative", scope.brushExtentInit)()
#				yMinNew = d3.min(scope.data, (d) -> d3.min(d.values, (d) -> d.delta))
#				yMaxNew = d3.max(scope.data, (d) -> d3.max(d.values, (d) -> d.delta))
#				axisNew = d3.svg.axis()
#						.scale d3.scale.linear().domain([yMinNew, yMaxNew]).range([scope.c.hFocus, 0])
#						.orient "left"
#						.ticks 5, "+%"
#				scope.c.yFocus.domain([yMinNew, yMaxNew])
#				scope.c.focus.select ".axis.yFocus"
#						.transition().duration(scope.c.transitionDuration)
#						.call axisNew
#				scope.c.focus.selectAll ".line.focus"
#						.transition().duration(scope.c.transitionDuration)
#						.attr "d", (d) -> scope.c.lineDelta(d.values)
			return

		return