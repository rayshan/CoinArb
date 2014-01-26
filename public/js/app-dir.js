// Generated by CoffeeScript 1.6.3
(function() {
  var dir;

  dir = angular.module('CaAppDir', ['ngAnimate']);

  dir.directive('caNumDisplay', function($animate) {
    return {
      templateUrl: 'partials/ca-num-display.html',
      replace: true,
      restrict: 'E',
      scope: {
        name: "@",
        type: "@",
        cur: "=",
        pre: "=",
        baseline: "=",
        baselineBest: "=",
        curId: "=",
        curBaseline: "=",
        preBaseline: "="
      },
      link: function(scope, ele, attrs) {
        var _numEle;
        _numEle = angular.element(ele[0].querySelector('.ca-main'));
        scope.getBaselineNameEng = function() {
          if (scope.baseline != null) {
            return scope.$parent.app.data[scope.baseline].displayNameEng;
          }
        };
        scope.show = function(input, equality) {
          return !isNaN(parseFloat(input)) && isFinite(input) && Math.abs(input) > equality;
        };
        scope.diff = function(cur, pre, pct) {
          if (pct === true) {
            return (cur - pre) / pre * 100;
          } else {
            return cur - pre;
          }
        };
        scope.diffBaseline = function(input, baseline) {
          if ((input != null) && (baseline != null)) {
            return Math.abs(input - baseline);
          }
        };
        scope.$on('tickerUpdate', function() {
          var c;
          if (scope.cur !== scope.pre && scope.show(scope.diff(scope.cur, scope.pre, true), 0.009)) {
            c = 'change';
            $animate.addClass(_numEle, c, function() {
              return $animate.removeClass(_numEle, c);
            });
          }
        });
      }
    };
  });

  dir.directive('caChart', function($q, $filter) {
    return {
      templateUrl: 'partials/ca-chart.html',
      restrict: 'E',
      scope: {
        data: "="
      },
      link: function(scope, ele, attrs) {
        var axisX, axisX2, axisY, brush, brushed, chart, chartCanvas, color, context, d3LoadData, dataParser, errorCb, focus, h, h2, hOrig, infoBox, legend, line, line2, margin, margin2, notifyCb, promise, renderCb, w, wOrig, x, x2, y, y2;
        scope.dataLoaded = false;
        scope.chartProcessed = false;
        chartCanvas = ele[0].querySelector(".ca-chart-line").children[0];
        wOrig = d3.select(chartCanvas).node().offsetWidth;
        hOrig = d3.select(chartCanvas).node().offsetHeight;
        margin = {
          t: 0,
          r: 50,
          b: 100,
          l: 50
        };
        margin2 = {
          t: 250,
          r: 50,
          b: 20,
          l: 50
        };
        w = wOrig - margin.l - margin.r;
        h = hOrig - margin.t - margin.b;
        h2 = hOrig - margin2.t - margin2.b;
        color = d3.scale.category10();
        x = d3.time.scale().range([0, w]);
        x2 = d3.time.scale().range([0, w]);
        y = d3.scale.linear().range([h, 0]);
        y2 = d3.scale.linear().range([h2, 0]);
        axisX = d3.svg.axis().scale(x).orient("bottom");
        axisX2 = d3.svg.axis().scale(x2).orient("bottom");
        axisY = d3.svg.axis().scale(y).orient("left").ticks(10, "$");
        line = d3.svg.line().interpolate("basis").x(function(d) {
          return x(d.date);
        }).y(function(d) {
          return y(d.close);
        });
        line2 = d3.svg.line().interpolate("basis").x(function(d) {
          return x2(d.date);
        }).y(function(d) {
          return y2(d.close);
        });
        brushed = function() {
          x.domain(brush.empty() ? x2.domain() : brush.extent());
          focus.selectAll("path.line").attr("d", function(d) {
            return line(d.values);
          });
          focus.select(".x1").call(axisX);
        };
        brush = d3.svg.brush().x(x2).on("brush", brushed);
        chart = d3.select(chartCanvas).attr("width", w + margin.l + margin.r).attr("height", h + margin.t + margin.b);
        chart.append("defs").append("clipPath").attr("id", "focus-clip").append("rect").attr("width", w).attr("height", h);
        focus = chart.append("g").attr('id', 'focus').attr("transform", "translate(" + margin.l + ", " + margin.t + ")");
        context = chart.append("g").attr('id', 'context').attr("transform", "translate(" + margin2.l + ", " + margin2.t + ")");
        infoBox = chart.append("g").attr('id', 'info-box').attr("transform", "translate(" + (margin.l * 2) + ", 0)");
        legend = function() {
          var items, lBox, lItems, lPadding;
          items = {};
          chart = d3.select(this.node().parentNode);
          lPadding = this.attr("data-style-padding") || 5;
          lBox = this.selectAll(".box").data([true]);
          lItems = this.selectAll(".items").data([true]);
          lBox.enter().append("rect").classed("box", true);
          lItems.enter().append("g").classed("items", true);
          chart.selectAll("[data-legend]").each(function() {
            var path;
            path = d3.select(this);
            items[path.attr("data-legend")] = {
              pos: path.attr("data-legend-pos") || this.getBBox().y,
              color: path.attr("data-legend-color") || (path.style("fill") !== "none" ? path.style("fill") : path.style("stroke"))
            };
          });
          items = d3.entries(items).sort(function(a, b) {
            return a.value.pos - b.value.pos;
          });
          lItems.selectAll("text").data(items, function(d) {
            return d.key;
          }).call(function(d) {
            return d.enter().append("text");
          }).call(function(d) {
            return d.exit().remove();
          }).attr("y", function(d, i) {
            return i + "em";
          }).attr("x", "1em").text(function(d) {
            return d.key;
          });
          lItems.selectAll("circle").data(items, function(d) {
            return d.key;
          }).call(function(d) {
            return d.enter().append("circle");
          }).call(function(d) {
            return d.exit().remove();
          }).attr("cy", function(d, i) {
            return i - 0.25 + "em";
          }).attr("cx", 0).attr("r", "0.4em").style("fill", function(d) {
            return d.value.color;
          });
        };
        renderCb = function(resolved) {
          var contextExchanges, focusExchanges, xMax, xMin, yMax, _chartProcessT, _data, _dataLoadT, _dataNested, _startTimeChart, _startTimeData, _tTotal;
          _data = resolved.data;
          _startTimeData = resolved.startTimeData;
          _startTimeChart = moment();
          scope.dataLoaded = true;
          _dataLoadT = moment.duration(_startTimeChart.diff(_startTimeData), 'ms').asSeconds();
          color.domain(d3.keys(_data[0]).filter(function(key) {
            return key === "exchange";
          }));
          _dataNested = d3.nest().key(function(d) {
            return d.exchange;
          }).entries(_data);
          xMin = d3.min(_dataNested, function(d) {
            return d3.min(d.values, function(d) {
              return d.date;
            });
          });
          xMax = d3.max(_dataNested, function(d) {
            return d3.max(d.values, function(d) {
              return d.date;
            });
          });
          yMax = d3.max(_dataNested, function(d) {
            return d3.max(d.values, function(d) {
              return d.close;
            });
          });
          x.domain([xMin, xMax]);
          y.domain([0, yMax]);
          x2.domain(x.domain());
          y2.domain(y.domain());
          focus.append("g").attr("class", "axis x1").attr("transform", "translate(0, " + h + ")").call(axisX);
          focus.append("g").attr("class", "axis y1").call(axisY).append("text").attr("class", "axis label").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", "1em").text("per Bitcoin");
          focusExchanges = focus.selectAll(".exchange").data(_dataNested, function(d) {
            return d.key;
          }).enter().append("g").attr("clip-path", "url(#focus-clip)").attr("class", "exchange");
          focusExchanges.append("path").attr("d", function(d) {
            return line(d.values);
          }).attr("data-legend", function(d) {
            return d.key;
          }).attr("class", "line focus").style("stroke", function(d) {
            return color(d.key);
          });
          focus.append("g").attr("class", "legend").attr("transform", "translate(50,30)").style("font-size", "12px").call(legend);
          context.append("g").attr("class", "axis x2").attr("transform", "translate(0, " + h2 + ")").call(axisX2);
          context.append("g").attr("class", "x brush").call(brush).selectAll("rect").attr("y", -6).attr("height", h2 + 7);
          contextExchanges = context.selectAll(".exchange").data(_dataNested, function(d) {
            return d.key;
          }).enter().append("g").attr("class", "exchange");
          contextExchanges.append("path").attr("class", "line").attr("d", function(d) {
            return line2(d.values);
          }).style("stroke", function(d) {
            return color(d.key);
          });
          scope.chartProcessed = true;
          _chartProcessT = moment.duration(moment().diff(_startTimeChart), 'ms').asSeconds();
          _tTotal = $filter("round")(_dataLoadT + _chartProcessT);
          infoBox.append("text").attr("dy", "1em").text("Generated by CoinArb in " + _tTotal + " s.");
        };
        errorCb = function(what) {
          console.log(what.msg, what.error);
        };
        notifyCb = function(what) {
          console.log(what);
        };
        dataParser = function(d) {
          d.date = d3.time.format("%m/%d/%y").parse(d.date);
          d.high = +d.high;
          d.low = +d.low;
          d.close = +d.close;
          d.volume = +d.volume;
          return d;
        };
        d3LoadData = function(uri) {
          var deferred, _startTimeData;
          _startTimeData = moment();
          deferred = $q.defer();
          d3.tsv(uri, dataParser, function(err, data) {
            if (err != null) {
              deferred.reject({
                msg: "didn't work",
                error: err,
                startTimeData: _startTimeData
              });
            } else {
              deferred.resolve({
                msg: "worked",
                data: data,
                startTimeData: _startTimeData
              });
            }
          });
          return deferred.promise;
        };
        promise = d3LoadData(scope.data);
        promise.then(renderCb, errorCb, notifyCb);
      }
    };
  });

  dir.directive('caSelectFocus', function($q, $filter) {});

}).call(this);

/*
//@ sourceMappingURL=app-dir.map
*/
