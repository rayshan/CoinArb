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
		scope.rendered = false

		# ===========================
		# pre-render things while data loads

		c = {} # chart

		c.canvas = ele[0].querySelector(".ca-chart-line").children[0]

		c.wOrig = d3.select(c.canvas).node().offsetWidth
		c.hOrig = d3.select(c.canvas).node().offsetHeight
#		hOrig = 300
#		console.log(wOrig, hOrig)
		# offsetW/H = border + padding + vertical scrollbar (if present & rendered) + CSS width
		c.margin =
			t: 0
			r: 50
			b: 100
			l: 50
		c.margin2 =
			t: 280
			r: 50
			b: 20
			l: 50
		c.w = c.wOrig - c.margin.l - c.margin.r
		c.h = c.hOrig - c.margin.t - c.margin.b
		c.h2 = c.hOrig - c.margin2.t - c.margin2.b

		c.color = d3.scale.category10() # 20 avail

		c.x = d3.time.scale().range([0, c.w])
		c.x2 = d3.time.scale().range([0, c.w])
		c.y = d3.scale.linear().range([c.h, 0])
		c.y2 = d3.scale.linear().range([c.h2, 0])

		c.axisX = d3.svg.axis().scale(c.x).orient("bottom")
		c.axisX2 = d3.svg.axis().scale(c.x2).orient("bottom")
		c.axisY = d3.svg.axis()
				.scale(c.y)
				.orient("left")
				.ticks(10, "$")

		c.line = d3.svg.line()
				.interpolate("basis")
				.x((d) -> c.x(d.date))
				.y((d) -> c.y(d.close))
		c.line2 = d3.svg.line()
				.interpolate("basis")
				.x((d) -> c.x2(d.date))
				.y((d) -> c.y2(d.close))

		c.brushed = ->
			c.x.domain(if c.brush.empty() then c.x2.domain() else c.brush.extent())
			#	y.domain(if brush.empty() then y2.domain() else brush.extent())
			c.focus.selectAll("path.line").attr("d", (d) -> c.line(d.values))
			c.focus.select(".x1").call(c.axisX)
#			focus.select(".y1").call(axisY)
			return
		c.brush = d3.svg.brush().x(c.x2).on("brush", c.brushed)

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

		errorCb = (what) -> console.log what.msg, what.error; return

		notifyCb = (what) -> console.log what; return

		promise = caD3Svc.fetch(scope.data)
		promise.then(caD3Svc.render(c), errorCb, notifyCb).then(() ->
			scope.rendered = true
		)

		return

dir.directive 'caSelectFocus', ($q, $filter) ->
	#	with copy to clipboard button
	return