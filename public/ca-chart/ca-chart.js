// Generated by CoffeeScript 1.7.1
(function() {
  var module;

  module = angular.module('CaChartModule', []);

  module.factory('caD3Svc', function($q, $filter) {
    var chartData, chartObj, dataParser, dataTransform, dateParser, legend, time;
    chartData = null;
    chartObj = null;
    time = {
      preRender: null,
      fetch: null,
      render: null
    };
    dateParser = function(input) {
      return d3.time.format("%m/%d/%y").parse(input);
    };
    dataParser = function(d) {
      d.date = dateParser(d.date);
      d.high = +d.high;
      d.low = +d.low;
      d.close = +d.close;
      d.volume = +d.volume;
      return d;
    };
    dataTransform = function(data, baseline, field) {
      chartData.some(function(exchange) {
        return exchange.key === baseline && (baseline = exchange.values);
      });
      baseline = baseline.reduce(function(output, item) {
        output[item.date] = item[field];
        return output;
      }, {});
      chartData.forEach(function(item) {
        item.values.forEach(function(valItem) {
          var bl, val;
          bl = baseline[valItem.date];
          val = valItem[field];
          valItem.delta = bl != null ? (bl === val ? 0 : val / bl - 1) : null;
        });
      });
    };
    legend = function() {
      var chart, items, lBox, lItems, lPadding;
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
    return {
      preRender: function(ele) {
        var axisXContext, axisXFocus, axisY, canvas, chart, color, context, focus, hContext, hFocus, hOrig, infoBox, lineContext, lineDelta, lineFocus, marginBase, marginContext, marginFocus, transitionDuration, w, wOrig, xContext, xFocus, yContext, yFocus, _deferred, _startT;
        _startT = moment();
        _deferred = $q.defer();
        transitionDuration = 250;
        canvas = ele[0].querySelector(".ca-chart-line").children[0];
        wOrig = d3.select(canvas).node().offsetWidth;
        hOrig = d3.select(canvas).node().offsetHeight;
        marginBase = 55;
        marginFocus = {
          t: 0,
          l: marginBase,
          r: 0,
          b: hOrig * .4
        };
        marginContext = {
          t: hOrig * .6 + marginBase / 2,
          l: marginBase,
          r: 0,
          b: marginBase * .4
        };
        w = wOrig - marginFocus.l - marginFocus.r;
        hFocus = hOrig - marginFocus.t - marginFocus.b;
        hContext = hOrig - marginContext.t - marginContext.b;
        color = d3.scale.category10();
        xFocus = d3.time.scale().range([0, w]);
        xContext = d3.time.scale().range([0, w]);
        yFocus = d3.scale.linear().range([hFocus, 0]);
        yContext = d3.scale.linear().range([hContext, 0]);
        axisXFocus = d3.svg.axis().scale(xFocus).orient("bottom");
        axisXContext = d3.svg.axis().scale(xContext).orient("bottom");
        axisY = d3.svg.axis().scale(yFocus).orient("left").ticks(10, "$");
        lineFocus = d3.svg.line().interpolate("basis").x(function(d) {
          return xFocus(d.date);
        }).y(function(d) {
          return yFocus(d.close);
        });
        lineContext = d3.svg.line().interpolate("basis").x(function(d) {
          return xContext(d.date);
        }).y(function(d) {
          return yContext(d.close);
        });
        lineDelta = d3.svg.line().interpolate("basis").x(function(d) {
          return xFocus(d.date);
        }).y(function(d) {
          return yFocus(d.delta);
        });
        chart = d3.select(canvas).attr("width", w + marginFocus.l + marginFocus.r).attr("height", hFocus + marginFocus.t + marginFocus.b);
        chart.append("defs").append("clipPath").attr("id", "focus-clip").append("rect").attr("width", w).attr("height", hFocus);
        focus = chart.append("g").attr('id', 'focus').attr("transform", "translate(" + marginFocus.l + ", " + marginFocus.t + ")");
        context = chart.append("g").attr('id', 'context').attr("transform", "translate(" + marginContext.l + ", " + marginContext.t + ")");
        infoBox = chart.append("g").attr('id', 'info-box').attr("transform", "translate(" + (marginFocus.l * 2) + ", 0)");
        chartObj = {
          transitionDuration: transitionDuration,
          hFocus: hFocus,
          hContext: hContext,
          xFocus: xFocus,
          xContext: xContext,
          yFocus: yFocus,
          yContext: yContext,
          axisXFocus: axisXFocus,
          axisXContext: axisXContext,
          axisY: axisY,
          lineFocus: lineFocus,
          lineContext: lineContext,
          lineDelta: lineDelta,
          color: color,
          focus: focus,
          context: context,
          infoBox: infoBox
        };
        time.preRender = moment.duration(moment().diff(_startT), 'ms').asSeconds();
        _deferred.resolve({
          msg: "pre-rendered"
        });
        return _deferred.promise;
      },
      fetch: function(uri) {
        var _deferred, _startT;
        _startT = moment();
        _deferred = $q.defer();
        d3.tsv(uri, dataParser, function(err, data) {
          if (err != null) {
            _deferred.reject({
              msg: "fetching failed",
              error: err
            });
          } else {
            chartData = d3.nest().key(function(d) {
              return d.exchange;
            }).entries(data);
            time.fetch = moment.duration(moment().diff(_startT), 'ms').asSeconds();
            _deferred.resolve({
              msg: "fetched"
            });
          }
        });
        return _deferred.promise;
      },
      render: function(chartType, brushExtentInit) {
        return function(resolve) {
          var c, contextExchanges, focusExchanges, xMax, xMin, yMax, _deferred, _startT;
          console.log(chartType);
          c = chartObj;
          _deferred = $q.defer();
          _startT = moment();
          c.brushed = function() {
            c.xFocus.domain(c.brush.empty() ? c.xContext.domain() : c.brush.extent());
            c.focus.selectAll("path.line").attr("d", function(d) {
              return c.lineFocus(d.values);
            });
            c.focus.select(".xFocus").call(c.axisXFocus);
          };
          c.brush = d3.svg.brush().x(c.xContext).on("brush", c.brushed);
          c.color.domain(chartData.map(function(d) {
            return d.key;
          }));
          xMin = d3.min(chartData, function(d) {
            return d3.min(d.values, function(d) {
              return d.date;
            });
          });
          xMax = d3.max(chartData, function(d) {
            return d3.max(d.values, function(d) {
              return d.date;
            });
          });
          yMax = d3.max(chartData, function(d) {
            return d3.max(d.values, function(d) {
              return d.close;
            });
          });
          c.xFocus.domain([xMin, xMax]);
          c.yFocus.domain([0, yMax]);
          c.xContext.domain(c.xFocus.domain());
          c.yContext.domain(c.yFocus.domain());
          c.focus.append("g").attr("class", "axis xFocus").attr("transform", "translate(0, " + c.hFocus + ")").call(c.axisXFocus);
          c.focus.append("g").attr("class", "axis yFocus").call(c.axisY).append("text").attr("class", "axis label").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", "1em").text("per Bitcoin");
          focusExchanges = c.focus.selectAll(".exchange").data(chartData, function(d) {
            return d.key;
          }).enter().append("g").attr("clip-path", "url(#focus-clip)").attr("class", "exchange");
          focusExchanges.append("path").attr("d", function(d) {
            return c.lineFocus(d.values);
          }).attr("data-legend", function(d) {
            return d.key;
          }).attr("class", "line focus").style("stroke", function(d) {
            return c.color(d.key);
          });
          c.focus.append("g").attr("class", "legend").attr("transform", "translate(50,30)").style("font-size", "12px").call(legend);
          c.context.append("g").attr("class", "axis xContext").attr("transform", "translate(0, " + c.hContext + ")").call(c.axisXContext);
          c.context.append("g").attr("class", "brush").call(c.brush).selectAll("rect").attr("y", -6).attr("height", c.hContext + 7);
          contextExchanges = c.context.selectAll(".exchange").data(chartData, function(d) {
            return d.key;
          }).enter().append("g").attr("class", "exchange");
          contextExchanges.append("path").attr("class", "line").attr("d", function(d) {
            return c.lineContext(d.values);
          }).style("stroke", function(d) {
            return c.color(d.key);
          });
          time.render = moment.duration(moment().diff(_startT), 'ms').asSeconds();
          _deferred.resolve();
          return _deferred.promise;
        };
      },
      renderInfoBox: function() {
        var t, _totalT;
        _totalT = 0;
        for (t in time) {
          _totalT += time[t];
        }
        chartObj.infoBox.append("text").attr("dy", "1em").text("Generated by CoinArb in " + ($filter("round")(_totalT)) + " s.");
      },
      transform: dataTransform,
      chartData: function() {
        return chartData;
      },
      chartObj: function() {
        return chartObj;
      }
    };
  });

  module.directive('caChart', function($q, $filter, caD3Svc) {
    return {
      templateUrl: 'ca-chart/ca-chart.html',
      restrict: 'E',
      scope: {
        data: "="
      },
      link: function(scope, ele) {
        var errorCb, fetchP, notifyCb, preRenderP;
        scope.rendered = false;
        scope.brushExtentInit = ["10/1/13", "1/15/14"];
        scope.baseline = scope.$parent.app.baseline;
        scope.$on("baselineSet", function(event, baseline) {
          scope.baseline = baseline;
        });
        preRenderP = caD3Svc.preRender(ele);
        fetchP = caD3Svc.fetch(scope.data);
        errorCb = function(what) {
          console.log(what);
        };
        notifyCb = function(what) {
          console.log(what);
        };
        $q.all([preRenderP, fetchP]).then(caD3Svc.render("relative", scope.brushExtentInit), errorCb, notifyCb).then(function() {
          caD3Svc.renderInfoBox();
          scope.rendered = true;
          scope.c = caD3Svc.chartObj();
          scope.data = caD3Svc.chartData();
        });
        scope.update = function(chartType) {
          var axisNew, yMaxNew, yMinNew;
          if (chartType === "absolute") {
            caD3Svc.render("absolute", scope.brushExtentInit)();
          } else {
            caD3Svc.transform(scope.data, scope.baseline, "close");
            yMinNew = d3.min(scope.data, function(d) {
              return d3.min(d.values, function(d) {
                return d.delta;
              });
            });
            yMaxNew = d3.max(scope.data, function(d) {
              return d3.max(d.values, function(d) {
                return d.delta;
              });
            });
            axisNew = d3.svg.axis().scale(d3.scale.linear().domain([yMinNew, yMaxNew]).range([scope.c.hFocus, 0])).orient("left").ticks(5, "+%");
            scope.c.yFocus.domain([yMinNew, yMaxNew]);
            scope.c.focus.select(".axis.yFocus").transition().duration(scope.c.transitionDuration).call(axisNew);
            scope.c.focus.selectAll(".line.focus").transition().duration(scope.c.transitionDuration).attr("d", function(d) {
              return scope.c.lineDelta(d.values);
            });
          }
        };
      }
    };
  });

}).call(this);

//# sourceMappingURL=ca-chart.map
