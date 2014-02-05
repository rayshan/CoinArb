svc = angular.module('CaAppSvc', [
	'ngResource'
	'btford.socket-io'
	'poller'
])

svc.factory 'caNotificationSvc', () ->
	enabled: false
	create: (data) ->
		if Notification.permission is not 'granted'
			Notification.requestPermission()

		n = new Notification 'yo', {
			body: data
		}
		return

svc.factory 'caCheckAndCopySvc', ($rootScope, exchangeSvc, caNotificationSvc) ->
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

svc.factory 'caTickerSvc', ($resource, $filter, poller, caSocketSvc, exchangeSvc, caCheckAndCopySvc) ->
	USDCNY = 6.05
	pollers = []

	notifyCb = (id) ->
		(res) ->
			switch id
				when "btcchina"
					current =
						last: $filter('round')(res.ticker.last / USDCNY)
						spread: $filter('round')((res.ticker.buy - res.ticker.sell) / USDCNY)
						# error: null
					caCheckAndCopySvc.process(id, current)
				when "mtgox"
					current =
						last: $filter('round')(res.data.last.value)
						spread: $filter('round')(res.data.buy.value - res.data.sell.value)
						# error: null
					caCheckAndCopySvc.process(id, current)
				when "btce"
					current =
						last: $filter('round')(res.query.results.ticker.last)
						spread: $filter('round')(res.query.results.ticker.buy - res.query.results.ticker.sell)
						# error: null
					caCheckAndCopySvc.process(id, current)
				when "bitfinex"
					current =
						last: $filter('round')(res.query.results.json.last_price)
						spread: $filter('round')(res.query.results.json.bid - res.query.results.json.ask)
						# error: null
					caCheckAndCopySvc.process(id, current)
				when "localbitcoins"
					current =
						last: $filter('round')(res.query.results.json.USD.avg_3h)
						# need to pull from trades / orderbook to compute bid ask spread (see localbitcoins api docs)
						# error: null
					caCheckAndCopySvc.process(id, current)
				else # all bitcoinaverage api
					current =
						last: $filter('round')(res[id].rates.last)
						spread: $filter('round')(res[id].rates.bid - res[id].rates.ask)
						# error: null
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

svc.factory 'caSocketSvc', ($rootScope, $filter, socketFactory, caCheckAndCopySvc) ->
	unsubscribe =
		depthBTCUSD:
			op: 'unsubscribe'
			channel: '24e67e0d-1cad-4cc0-9e7a-f8523ef460fe'
		tradeBTC:
			op: 'unsubscribe'
			channel: 'dbf1dee9-4f2e-4a08-8cb7-748919a71b21'

	process: (data) ->
		socket = socketFactory({
#			ioSocket: io.connect data.api.uri
#		ioSocket: io.connect 'https://socketio.mtgox.com:443/mtgox?Currency=USD', {secure: true} # certificate expired in April 2013 WTF
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

svc.factory 'caD3Svc', ($q, $filter) ->
	dateParser = (input) -> d3.time.format("%m/%d/%y").parse(input)
	dataParser = (d) ->
		d.date = dateParser(d.date) # %x doesn't work b/c uses %Y which has century prefix
		d.high = +d.high
		d.low = +d.low
		d.close = +d.close
		d.volume = +d.volume
		d

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

		c = {} # chart

		c.transitionDuration = 250

		c.canvas = ele[0].querySelector(".ca-chart-line").children[0]

#		c.update = -> c.canvas.transition().duration(c.transitionDuration).call(c)

		# positioning & sizing

		c.wOrig = d3.select(c.canvas).node().offsetWidth
		c.hOrig = d3.select(c.canvas).node().offsetHeight
		# offsetW / H = border + padding + vertical scrollbar (if present & rendered) + CSS width
		c.marginBase = 55 # for multipliers
		c.margin =
			t: 0
			l: c.marginBase, r: 0
			b: c.hOrig * .4
		c.margin2 =
			t: c.hOrig * .6 + c.marginBase / 2
			l: c.marginBase, r: 0
			b: c.marginBase * .4
		c.w = c.wOrig - c.margin.l - c.margin.r
		c.h = c.hOrig - c.margin.t - c.margin.b
		c.h2 = c.hOrig - c.margin2.t - c.margin2.b

		# scales
		c.color = d3.scale.category10() # 20 avail
		c.x = d3.time.scale().range([0, c.w])
		c.x2 = d3.time.scale().range([0, c.w])
		c.y = d3.scale.linear().range([c.h, 0])
		c.y2 = d3.scale.linear().range([c.h2, 0])


		# axis
		c.axisX = d3.svg.axis().scale(c.x).orient("bottom")
		c.axisX2 = d3.svg.axis().scale(c.x2).orient("bottom")
		c.axisY = d3.svg.axis()
				.scale c.y
				.orient "left"
				.ticks 10, "$"

		# line rendering f, 1 for focus, 1 for context
		c.line = d3.svg.line()
				.interpolate("basis")
				.x (d) -> c.x d.date
				.y (d) -> c.y d.close
		c.line2 = d3.svg.line()
				.interpolate "basis"
				.x (d) -> c.x2 d.date
				.y (d) -> c.y2 d.close

		c.chart = d3.select(c.canvas)
				.attr("width", c.w + c.margin.l + c.margin.r)
				.attr("height", c.h + c.margin.t + c.margin.b)

		c.chart.append("defs").append("clipPath") # defining for later reuse
				.attr("id", "focus-clip")
				.append("rect")
				.attr("width", c.w)
				.attr("height", c.h)

		c.focus = c.chart.append("g")
				.attr('id', 'focus')
				.attr("transform", "translate(#{ c.margin.l }, #{ c.margin.t })")

		c.context = c.chart.append("g")
				.attr('id', 'context')
				.attr("transform", "translate(#{ c.margin2.l }, #{ c.margin2.t })")

		c.infoBox = c.chart.append("g")
				.attr('id', 'info-box')
				.attr("transform", "translate(#{ c.margin.l * 2 }, 0)")

		_deferred.resolve {
			msg: "pre-rendered"
			c: c
			t: moment.duration(moment().diff(_startT), 'ms').asSeconds()
		}
		_deferred.promise

	fetch: (uri) -> # incl. data process
		console.log("fetched <- make sure only once")

		_startT = moment()
		_deferred = $q.defer()

		d3.tsv uri, dataParser, (err, data) ->
			# deferred.notify "working..."
			if err?
				_deferred.reject {
					msg: "fetching failed"
					error: err
					t: moment.duration(moment().diff(_startT), 'ms').asSeconds()
				}
			else
				_exchanges = Object.keys(d3.nest()
						.key((d) -> d.exchange)
						.rollup((leaves) -> return null) # just need to roll up, has to specify a f()
						.map(data))

				_dataNested = d3.nest()
						.key((d) -> d.exchange) # group by this key
						.entries(data) # apply to this data

				_deferred.resolve {
					msg: "fetched"
					data: _dataNested
					keys: _exchanges
					t: moment.duration(moment().diff(_startT), 'ms').asSeconds()
				}
			return
		_deferred.promise

	render: (resolve) ->
		c = resolve[0].c
		resolved = resolve[1]

		_deferred = $q.defer()

		_startT = moment()

		# brush
		c.brushExtend = null # change this for date grouping
		c.brushExtend = [dateParser("1/1/13"), dateParser("12/31/13")] # change this for date grouping
		c.brushed = ->
			c.x.domain(if c.brush.empty() then c.x2.domain() else c.brush.extent())
			#			yMax = d3.max(resolved.data, (d) -> d3.max(d.values, (d) -> d.close))
			#			c.y.domain([0, yMax])
			#			c.y.domain(if c.brush.empty() then c.y.domain() else c.brush.extent())
			c.focus.selectAll("path.line").attr("d", (d) -> c.line(d.values))
			c.focus.select(".x1").call(c.axisX)
			#			c.focus.select(".y1").call(c.axisY)
			return
		c.brush = d3.svg.brush().x(c.x2)
		c.brush.extent(c.brushExtend) if c.brushExtend?
		c.brush.on("brush", c.brushed) # .x only so don't brush y axis

		# ===========================
		# render all

		# color.domain(d3.keys(_data[0]).filter((key) -> key is "exchange")) # just returns ['exchange'], not sure what for
		c.color.domain(resolved.keys)
		# color domain optional but a good idea for deterministic behavior, as inferring the domain from usage will be dependent on ordering

		xMin = d3.min(resolved.data, (d) -> d3.min(d.values, (d) -> d.date))
		xMax = d3.max(resolved.data, (d) -> d3.max(d.values, (d) -> d.date))
		yMax = d3.max(resolved.data, (d) -> d3.max(d.values, (d) -> d.close))
		c.x.domain([xMin, xMax])
		c.y.domain([0, yMax])
		c.x2.domain(c.x.domain())
		c.y2.domain(c.y.domain())

		# render x axis
		c.focus.append("g")
				.attr "class", "axis x1"
				.attr "transform", "translate(0, #{ c.h })"
				.call c.axisX

		# render y axis
		c.focus.append("g")
				.attr "class", "axis y1"
				.call c.axisY
			.append "text"
				.attr "class", "axis label"
				.attr "transform", "rotate(-90)"
				.attr "y", 6
				.attr "dy", "1em" # shift along y axis
				.text "per Bitcoin"

		# render clip path & g for lines
		focusExchanges = c.focus.selectAll ".exchange"
				.data resolved.data, (d) -> d.key
			.enter().append "g"
				.attr "clip-path", "url(#focus-clip)"
				.attr "class", "exchange"

		# render lines
		focusExchanges.append("path")
				.attr("d", (d) -> c.line(d.values))
				.attr("data-legend", (d) -> d.key) # add this attr for legend f() to render legend
				.attr("class", "line focus") # focus:hover changes stroke-width
				.style("stroke", (d) -> c.color(d.key))

		# render legend
		c.focus.append("g")
				.attr("class", "legend")
				.attr("transform", "translate(50,30)")
				.style("font-size", "12px")
				.call(legend)

		# ============================

		# render x axis
		c.context.append("g")
				.attr("class", "axis x2")
				.attr("transform", "translate(0, #{ c.h2 })")
				.call(c.axisX2)

		# render y axis
		c.context.append("g")
				.attr("class", "x brush")
				.call(c.brush)
			.selectAll("rect")
				.attr("y", -6)
				.attr("height", c.h2 + 7)

		# render g for lines
		contextExchanges = c.context.selectAll(".exchange")
				.data(resolved.data, (d) -> d.key)
				.enter().append("g")
				.attr("class", "exchange")

		# render lines
		contextExchanges.append("path")
				.attr("class", "line")
				.attr("d", (d) -> c.line2(d.values))
				.style("stroke", (d) -> c.color(d.key))

		# ============================

		_renderT = moment.duration(moment().diff(_startT), 'ms').asSeconds()
		_totalT = $filter("round")(resolved.t + _renderT)

		c.infoBox.append("text")
				.attr("dy", "1em") # shift along y axis from top
				.text("Generated by CoinArb in #{ _totalT } s.")

		_deferred.resolve()

		_deferred.promise