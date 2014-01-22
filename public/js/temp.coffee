margin =
	top: 25
	right: 40
	bottom: 35
	left: 85

w = 500 - margin.left - margin.right
h = 350 - margin.top - margin.bottom
padding = 10
colors = [
	["Local", "#377EB8"],
	["Global", "#4DAF4A"]
]
dataset = [
	keyword: "payday loans"
	global: 1400000
	local: 673000
	cpc: "14.11"
,
	keyword: "title loans"
	global: 165000
	local: 160000
	cpc: "12.53"
,
	keyword: "personal loans"
	global: 550000
	local: 301000
	cpc: "6.14"
,
	keyword: "online personal loans"
	global: 15400
	local: 12900
	cpc: "5.84"
,
	keyword: "online title loans"
	global: 111600
	local: 11500
	cpc: "11.74"
]
xScale = d3.scale.ordinal().domain(d3.range(dataset.length)).rangeRoundBands([0, w], 0.05)

# ternary operator to determine if global or local has a larger scale
yScale = d3.scale.linear().domain([
	0, d3.max(dataset, (d) ->
		(if (d.local > d.global) then d.local else d.global)
	)
]).range([h, 0])
xAxis = d3.svg.axis().scale(xScale).orient("bottom")
yAxis = d3.svg.axis().scale(yScale).orient("left").ticks(5)
global = (d) ->
	d.global

cpc = (d) ->
	d.cpc

commaFormat = d3.format(",")

#SVG element
svg = d3.select("#searchVolume").append("svg").attr("width", w + margin.left + margin.right).attr("height",
		h + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")

# Graph Bars
sets = svg.selectAll(".set").data(dataset).enter().append("g").attr("class", "set").attr("transform", (d, i) ->
	"translate(" + xScale(i) + ",0)"
)
sets.append("rect").attr("class", "local").attr("width", xScale.rangeBand() / 2).attr("y",(d) ->
	yScale d.local
).attr("x", xScale.rangeBand() / 2).attr("height",(d) ->
	h - yScale(d.local)
).attr("fill", colors[0][1]).append("text").text((d) ->
	commaFormat d.local
).attr("text-anchor", "middle").attr("x",(d, i) ->
	xScale(i) + xScale.rangeBand() / 2
).attr("y",(d) ->
	h - yScale(d.local) + 14
).attr("font-family", "sans-serif").attr("font-size", "11px").attr "fill", "black"
sets.append("rect").attr("class", "global").attr("width", xScale.rangeBand() / 2).attr("y",(d) ->
	yScale d.global
).attr("height",(d) ->
	h - yScale(d.global)
).attr("fill", colors[1][1]).append("text").text((d) ->
	commaFormat d.global
).attr("text-anchor", "middle").attr("x",(d, i) ->
	xScale(i) + xScale.rangeBand() / 2
).attr("y",(d) ->
	h - yScale(d.global) + 14
).attr("font-family", "sans-serif").attr("font-size", "11px").attr "fill", "red"

# xAxis
# Add the X Axis
svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + (h) + ")").call xAxis

# yAxis
svg.append("g").attr("class", "y axis").attr("transform", "translate(0 ,0)").call yAxis

# xAxis label
svg.append("text").attr("transform", "translate(" + (w / 2) + " ," + (h + margin.bottom - 5) + ")").style("text-anchor",
		"middle").text "Keyword"

#yAxis label
svg.append("text").attr("transform", "rotate(-90)").attr("y", 0 - margin.left).attr("x", 0 - (h / 2)).attr("dy",
		"1em").style("text-anchor", "middle").text "Searches"

# Title
svg.append("text").attr("x", (w / 2)).attr("y", 0 - (margin.top / 2)).attr("text-anchor", "middle").style("font-size",
		"16px").style("text-decoration", "underline").text "Global & Local Searches"

# add legend

#.attr("x", w - 65)
#.attr("y", 50)
legend = svg.append("g").attr("class", "legend").attr("height", 100).attr("width", 100).attr("transform",
		"translate(-20,50)")
legendRect = legend.selectAll("rect").data(colors)
legendRect.enter().append("rect").attr("x", w - 65).attr("width", 10).attr "height", 10
legendRect.attr("y",(d, i) ->
	i * 20
).style "fill", (d) ->
	d[1]

legendText = legend.selectAll("text").data(colors)
legendText.enter().append("text").attr "x", w - 52
legendText.attr("y",(d, i) ->
	i * 20 + 9
).text (d) ->
	d[0]
