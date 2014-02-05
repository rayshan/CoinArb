nv.models.lineWithFocusChart = ->

	chart = (selection) ->
		selection.each (data) ->

			resizePath = (d) ->
				e = +(d is "e")
				x = (if e then 1 else -1)
				y = availableHeight2 / 3
				"M" + (.5 * x) + "," + y + "A6,6 0 0 " + e + " " + (6.5 * x) + "," + (y + 6) + "V" + (2 * y - 6) + "A6,6 0 0 " + e + " " + (.5 * x) + "," + (2 * y) + "Z" + "M" + (2.5 * x) + "," + (y + 8) + "V" + (2 * y - 8) + "M" + (4.5 * x) + "," + (y + 8) + "V" + (2 * y - 8)
			updateBrushBG = ->
				brush.extent brushExtent  unless brush.empty()
				brushBG.data([(if brush.empty() then x2.domain() else brushExtent)]).each (d, i) ->
					leftWidth = x2(d[0]) - x.range()[0]
					rightWidth = x.range()[1] - x2(d[1])
					d3.select(this).select(".left").attr "width", (if leftWidth < 0 then 0 else leftWidth)
					d3.select(this).select(".right").attr("x", x2(d[1])).attr "width", (if rightWidth < 0 then 0 else rightWidth)
					return

				return
			onBrush = ->
				brushExtent = (if brush.empty() then null else brush.extent())
				extent = (if brush.empty() then x2.domain() else brush.extent())

				#The brush extent cannot be less than one.  If it is, don't update the line chart.
				return  if Math.abs(extent[0] - extent[1]) <= 1
				dispatch.brush
					extent: extent
					brush: brush

				updateBrushBG()

				# Update Main (Focus)
				focusLinesWrap = g.select(".nv-focus .nv-linesWrap").datum(data.filter((d) ->
					not d.disabled
				).map((d, i) ->
					key: d.key
					values: d.values.filter((d, i) ->
						lines.x()(d, i) >= extent[0] and lines.x()(d, i) <= extent[1]
					)
				))
				focusLinesWrap.transition().duration(transitionDuration).call lines

				# Update Main (Focus) Axes
				g.select(".nv-focus .nv-x.nv-axis").transition().duration(transitionDuration).call xAxis
				g.select(".nv-focus .nv-y.nv-axis").transition().duration(transitionDuration).call yAxis
				return
			container = d3.select(this)
			that = this
			availableWidth = (width or parseInt(container.style("width")) or 960) - margin.left - margin.right
			availableHeight1 = (height or parseInt(container.style("height")) or 400) - margin.top - margin.bottom - height2
			availableHeight2 = height2 - margin2.top - margin2.bottom
			chart.update = ->
				container.transition().duration(transitionDuration).call chart
				return

			chart.container = this
			if not data or not data.length or not data.filter((d) ->
				d.values.length
			).length
				noDataText = container.selectAll(".nv-noData").data([noData])
				noDataText.enter().append("text").attr("class", "nvd3 nv-noData").attr("dy", "-.7em").style "text-anchor", "middle"
				noDataText.attr("x", margin.left + availableWidth / 2).attr("y", margin.top + availableHeight1 / 2).text (d) ->
					d

				return chart
			else
				container.selectAll(".nv-noData").remove()
			x = lines.xScale()
			y = lines.yScale()
			x2 = lines2.xScale()
			y2 = lines2.yScale()
			wrap = container.selectAll("g.nv-wrap.nv-lineWithFocusChart").data([data])
			gEnter = wrap.enter().append("g").attr("class", "nvd3 nv-wrap nv-lineWithFocusChart").append("g")
			g = wrap.select("g")
			gEnter.append("g").attr "class", "nv-legendWrap"
			focusEnter = gEnter.append("g").attr("class", "nv-focus")
			focusEnter.append("g").attr "class", "nv-x nv-axis"
			focusEnter.append("g").attr "class", "nv-y nv-axis"
			focusEnter.append("g").attr "class", "nv-linesWrap"
			contextEnter = gEnter.append("g").attr("class", "nv-context")
			contextEnter.append("g").attr "class", "nv-x nv-axis"
			contextEnter.append("g").attr "class", "nv-y nv-axis"
			contextEnter.append("g").attr "class", "nv-linesWrap"
			contextEnter.append("g").attr "class", "nv-brushBackground"
			contextEnter.append("g").attr "class", "nv-x nv-brush"
			if showLegend
				legend.width availableWidth
				g.select(".nv-legendWrap").datum(data).call legend
				unless margin.top is legend.height()
					margin.top = legend.height()
					availableHeight1 = (height or parseInt(container.style("height")) or 400) - margin.top - margin.bottom - height2
				g.select(".nv-legendWrap").attr "transform", "translate(0," + (-margin.top) + ")"
			wrap.attr "transform", "translate(" + margin.left + "," + margin.top + ")"
			lines.width(availableWidth).height(availableHeight1).color data.map((d, i) ->
				d.color or color(d, i)
			).filter((d, i) ->
				not data[i].disabled
			)
			lines2.defined(lines.defined()).width(availableWidth).height(availableHeight2).color data.map((d, i) ->
				d.color or color(d, i)
			).filter((d, i) ->
				not data[i].disabled
			)
			g.select(".nv-context").attr "transform", "translate(0," + (availableHeight1 + margin.bottom + margin2.top) + ")"
			contextLinesWrap = g.select(".nv-context .nv-linesWrap").datum(data.filter((d) ->
				not d.disabled
			))
			d3.transition(contextLinesWrap).call lines2
			xAxis.scale(x).ticks(availableWidth / 100).tickSize -availableHeight1, 0
			yAxis.scale(y).ticks(availableHeight1 / 36).tickSize -availableWidth, 0
			g.select(".nv-focus .nv-x.nv-axis").attr "transform", "translate(0," + availableHeight1 + ")"
			brush.x(x2).on "brush", ->
				oldTransition = chart.transitionDuration()
				chart.transitionDuration 0
				onBrush()
				chart.transitionDuration oldTransition
				return

			brush.extent brushExtent  if brushExtent
			brushBG = g.select(".nv-brushBackground").selectAll("g").data([brushExtent or brush.extent()])
			brushBGenter = brushBG.enter().append("g")
			brushBGenter.append("rect").attr("class", "left").attr("x", 0).attr("y", 0).attr "height", availableHeight2
			brushBGenter.append("rect").attr("class", "right").attr("x", 0).attr("y", 0).attr "height", availableHeight2
			gBrush = g.select(".nv-x.nv-brush").call(brush)
			gBrush.selectAll("rect").attr "height", availableHeight2
			gBrush.selectAll(".resize").append("path").attr "d", resizePath
			onBrush()
			x2Axis.scale(x2).ticks(availableWidth / 100).tickSize -availableHeight2, 0
			g.select(".nv-context .nv-x.nv-axis").attr "transform", "translate(0," + y2.range()[0] + ")"
			d3.transition(g.select(".nv-context .nv-x.nv-axis")).call x2Axis
			y2Axis.scale(y2).ticks(availableHeight2 / 36).tickSize -availableWidth, 0
			d3.transition(g.select(".nv-context .nv-y.nv-axis")).call y2Axis
			g.select(".nv-context .nv-x.nv-axis").attr "transform", "translate(0," + y2.range()[0] + ")"
			legend.dispatch.on "stateChange", (newState) ->
				chart.update()
				return

			dispatch.on "tooltipShow", (e) ->
				showTooltip e, that.parentNode  if tooltips
				return

			return


		#============================================================
		chart
	"use strict"
	lines = nv.models.line()
	lines2 = nv.models.line()
	xAxis = nv.models.axis()
	yAxis = nv.models.axis()
	x2Axis = nv.models.axis()
	y2Axis = nv.models.axis()
	legend = nv.models.legend()
	brush = d3.svg.brush()
	margin =
		top: 30
		right: 30
		bottom: 30
		left: 60

	margin2 =
		top: 0
		right: 30
		bottom: 20
		left: 60

	color = nv.utils.defaultColor()
	width = null
	height = null
	height2 = 100
	x = undefined
	y = undefined
	x2 = undefined
	y2 = undefined
	showLegend = true
	brushExtent = null
	tooltips = true
	tooltip = (key, x, y, e, graph) ->
		"<h3>" + key + "</h3>" + "<p>" + y + " at " + x + "</p>"

	noData = "No Data Available."
	dispatch = d3.dispatch("tooltipShow", "tooltipHide", "brush")
	transitionDuration = 250
	lines.clipEdge true
	lines2.interactive false
	xAxis.orient("bottom").tickPadding 5
	yAxis.orient "left"
	x2Axis.orient("bottom").tickPadding 5
	y2Axis.orient "left"
	showTooltip = (e, offsetElement) ->
		left = e.pos[0] + (offsetElement.offsetLeft or 0)
		top = e.pos[1] + (offsetElement.offsetTop or 0)
		x = xAxis.tickFormat()(lines.x()(e.point, e.pointIndex))
		y = yAxis.tickFormat()(lines.y()(e.point, e.pointIndex))
		content = tooltip(e.series.key, x, y, e, chart)
		nv.tooltip.show [
			left
			top
		], content, null, null, offsetElement
		return


	#============================================================
	# Event Handling/Dispatching (out of chart's scope)
	#------------------------------------------------------------
	lines.dispatch.on "elementMouseover.tooltip", (e) ->
		e.pos = [
			e.pos[0] + margin.left
			e.pos[1] + margin.top
		]
		dispatch.tooltipShow e
		return

	lines.dispatch.on "elementMouseout.tooltip", (e) ->
		dispatch.tooltipHide e
		return

	dispatch.on "tooltipHide", ->
		nv.tooltip.cleanup()  if tooltips
		return


	#============================================================

	#============================================================
	# Expose Public Variables
	#------------------------------------------------------------

	# expose chart's sub-components
	chart.dispatch = dispatch
	chart.legend = legend
	chart.lines = lines
	chart.lines2 = lines2
	chart.xAxis = xAxis
	chart.yAxis = yAxis
	chart.x2Axis = x2Axis
	chart.y2Axis = y2Axis
	d3.rebind chart, lines, "defined", "isArea", "size", "xDomain", "yDomain", "xRange", "yRange", "forceX", "forceY", "interactive", "clipEdge", "clipVoronoi", "id"
	chart.options = nv.utils.optionsFunc.bind(chart)
	chart.x = (_) ->
		return lines.x  unless arguments_.length
		lines.x _
		lines2.x _
		chart

	chart.y = (_) ->
		return lines.y  unless arguments_.length
		lines.y _
		lines2.y _
		chart

	chart.margin = (_) ->
		return margin  unless arguments_.length
		margin.top = (if typeof _.top isnt "undefined" then _.top else margin.top)
		margin.right = (if typeof _.right isnt "undefined" then _.right else margin.right)
		margin.bottom = (if typeof _.bottom isnt "undefined" then _.bottom else margin.bottom)
		margin.left = (if typeof _.left isnt "undefined" then _.left else margin.left)
		chart

	chart.margin2 = (_) ->
		return margin2  unless arguments_.length
		margin2 = _
		chart

	chart.width = (_) ->
		return width  unless arguments_.length
		width = _
		chart

	chart.height = (_) ->
		return height  unless arguments_.length
		height = _
		chart

	chart.height2 = (_) ->
		return height2  unless arguments_.length
		height2 = _
		chart

	chart.color = (_) ->
		return color  unless arguments_.length
		color = nv.utils.getColor(_)
		legend.color color
		chart

	chart.showLegend = (_) ->
		return showLegend  unless arguments_.length
		showLegend = _
		chart

	chart.tooltips = (_) ->
		return tooltips  unless arguments_.length
		tooltips = _
		chart

	chart.tooltipContent = (_) ->
		return tooltip  unless arguments_.length
		tooltip = _
		chart

	chart.interpolate = (_) ->
		return lines.interpolate()  unless arguments_.length
		lines.interpolate _
		lines2.interpolate _
		chart

	chart.noData = (_) ->
		return noData  unless arguments_.length
		noData = _
		chart


	# Chart has multiple similar Axes, to prevent code duplication, probably need to link all axis functions manually like below
	chart.xTickFormat = (_) ->
		return xAxis.tickFormat()  unless arguments_.length
		xAxis.tickFormat _
		x2Axis.tickFormat _
		chart

	chart.yTickFormat = (_) ->
		return yAxis.tickFormat()  unless arguments_.length
		yAxis.tickFormat _
		y2Axis.tickFormat _
		chart

	chart.brushExtent = (_) ->
		return brushExtent  unless arguments_.length
		brushExtent = _
		chart

	chart.transitionDuration = (_) ->
		return transitionDuration  unless arguments_.length
		transitionDuration = _
		chart


	#============================================================
	chart