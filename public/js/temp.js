function drawChart() {
	var margin = {
				top: 5,
				right: 10,
				bottom: 100,
				left: 50
			},
			margin2 = {
				top: 200,
				right: 10,
				bottom: 20,
				left: 50
			},
			width = 1075 - margin.left - margin.right,
			height = 280 - margin.top - margin.bottom,
			height2 = 280 - margin2.top - margin2.bottom;

	var parseDate = d3.time.format("%Y-%m-%d").parse;

	var x = d3.time.scale().range([0, width]),
			x2 = d3.time.scale().range([0, width]),
			y = d3.scale.linear().range([height, 0]),
			y2 = d3.scale.linear().range([height2, 0]);

	var xAxis = d3.svg.axis().scale(x).orient("bottom"),
			xAxis2 = d3.svg.axis().scale(x2).orient("bottom"),
			yAxis = d3.svg.axis().scale(y).orient("left");

	var brush = d3.svg.brush()
			.x(x2)
			.on("brush", brush);

	var area = function (color) {
		return d3.svg.area()
				.interpolate("monotone")
				.x(function (d) {
					return x(d.date);
				})
				.y0(height)
				.y1(function (d) {
					return y(d[color]);
				});
	};

	var area2 = function (color) {
		return d3.svg.area()
				.interpolate("monotone")
				.x(function (d) {
					return x2(d.date);
				})
				.y0(height2)
				.y1(function (d) {
					return y2(d[color]);
				});
	};

	var svg = d3.select("#dashboardChart #svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom);

	svg.append("defs").append("clipPath")
			.attr("id", "clip")
			.append("rect")
			.attr("width", width)
			.attr("height", height);

	var focus = svg.append("g")
			.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

	var context = svg.append("g")
			.attr("transform", "translate(" + margin2.left + "," + margin2.top + ")");

	var data = [{
		"date": "2013-02-08T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 1
	}, {
		"date": "2013-02-07T05:00:00.000Z",
		"data": null,
		"red": 485,
		"yellow": 0,
		"green": 491
	}, {
		"date": "2013-02-06T05:00:00.000Z",
		"data": null,
		"red": 2884,
		"yellow": 0,
		"green": 288
	}, {
		"date": "2013-02-05T05:00:00.000Z",
		"data": null,
		"red": 3191,
		"yellow": 0,
		"green": 3188
	}, {
		"date": "2013-02-04T05:00:00.000Z",
		"data": null,
		"red": 180,
		"yellow": 0,
		"green": 184
	}, {
		"date": "2013-02-03T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-02-02T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-02-01T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-31T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-30T05:00:00.000Z",
		"data": null,
		"red": 1,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-29T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 2
	}, {
		"date": "2013-01-28T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-27T05:00:00.000Z",
		"data": null,
		"red": 1,
		"yellow": 1,
		"green": 1
	}, {
		"date": "2013-01-26T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 1
	}, {
		"date": "2013-01-25T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-24T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-23T05:00:00.000Z",
		"data": null,
		"red": 49,
		"yellow": 0,
		"green": 45
	}, {
		"date": "2013-01-22T05:00:00.000Z",
		"data": null,
		"red": 59,
		"yellow": 0,
		"green": 64
	}, {
		"date": "2013-01-21T05:00:00.000Z",
		"data": null,
		"red": 119,
		"yellow": 1,
		"green": 125
	}, {
		"date": "2013-01-20T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 1,
		"green": 0
	}, {
		"date": "2013-01-19T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-18T05:00:00.000Z",
		"data": null,
		"red": 84,
		"yellow": 10,
		"green": 1
	}, {
		"date": "2013-01-17T05:00:00.000Z",
		"data": null,
		"red": 76,
		"yellow": 1,
		"green": 77
	}, {
		"date": "2013-01-16T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 1,
		"green": 0
	}, {
		"date": "2013-01-15T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 1000,
		"green": 10
	}, {
		"date": "2013-01-14T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-13T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-12T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}, {
		"date": "2013-01-11T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 10,
		"green": 0
	}, {
		"date": "2013-01-10T05:00:00.000Z",
		"data": null,
		"red": 0,
		"yellow": 0,
		"green": 0
	}];

	data.map(function (t) {
		t.date = new Date(t.date);
	});

	x.domain(d3.extent(data.map(function (d) {
		return d.date;
	})));
	y.domain([0, d3.max(data.map(function (d) {
		return d.red;
	}))]);

	x2.domain(x.domain());
	y2.domain(y.domain());

	focus.selectAll('path')
			.data(['red', 'yellow', 'green'])
			.enter()
			.append('path')
			.attr('clip-path', 'url(#clip)')
			.attr('d', function (col) {
				return area(col)(data);
			})
			.attr('class', function (col) {
				return "path_" + col + " data";
			});

	focus.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0," + height + ")")
			.call(xAxis);

	focus.append("g")
			.attr("class", "y axis")
			.call(yAxis);

	context.selectAll('path')
			.data(['red', 'yellow', 'green'])
			.enter()
			.append('path')
			.attr('d', function (col) {
				return area2(col)(data);
			})
			.attr('class', function (col) {
				return "path_" + col;
			});

	context.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0," + height2 + ")")
			.call(xAxis2);

	context.append("g")
			.attr("class", "x brush")
			.call(brush)
			.selectAll("rect")
			.attr("y", -6)
			.attr("height", height2 + 7);

	function brush() {
		x.domain(brush.empty() ? x2.domain() : brush.extent());
		focus.selectAll("path.data").attr("d", function (col) { return area(col)(data); });
		focus.select(".x.axis").call(xAxis);
	}
}
drawChart();