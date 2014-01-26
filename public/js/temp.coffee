# Any elements that have a title set in the "data-legend" attribute will be included when f() is called
# can define these as attr for override:
# data-legend-pos
# data-legend-color
# data-style-padding

legend = (g) -> # g should be classed legend
	g.each ->
		items = {}

		g = d3.select(this) # this is already current selection?
		svg = d3.select(g.property("nearestViewportElement")) # is this supposed to select the whole parent chart?

		legendPadding = g.attr("data-style-padding") or 5

		lBox = g.selectAll(".box").data([true])
		lItems = g.selectAll(".items").data([true])

		lBox.enter().append("rect").classed "box", true
		lItems.enter().append("g").classed "items", true

		svg.selectAll("[data-legend]").each -> # why brackets?
			self = d3.select(this)
			items[self.attr("data-legend")] = # returns attr that's the name of series of the only element; b/c 2nd arg == null
				pos: self.attr("data-legend-pos") or @getBBox().y # getBBox() is w3 svg spec
				color:
					self.attr("data-legend-color") || if self.style("fill") isnt "none" then self.style("fill") else self.style("stroke")

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

		# Reposition and resize the box
		lbbox = lItems[0][0].getBBox()
		lBox.attr("x", (lbbox.x - legendPadding))
		.attr("y", (lbbox.y - legendPadding))
		.attr("height", (lbbox.height + 2 * legendPadding))
		.attr("width", (lbbox.width + 2 * legendPadding))

	g