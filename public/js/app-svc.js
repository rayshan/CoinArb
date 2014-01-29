// Generated by CoffeeScript 1.7.0
(function() {
  var svc;

  svc = angular.module('CaAppSvc', ['ngResource', 'btford.socket-io', 'poller']);

  svc.factory('caNotificationSvc', function() {
    return {
      enabled: false,
      create: function(data) {
        var n;
        if (Notification.permission === !'granted') {
          Notification.requestPermission();
        }
        n = new Notification('yo', {
          body: data
        });
      }
    };
  });

  svc.factory('caCheckAndCopySvc', function($rootScope, exchangeSvc, caNotificationSvc) {
    return {
      process: function(id, current) {
        var changed, data, now;
        now = moment();
        data = exchangeSvc.data[id].fetched;
        if (data.initialized === false) {
          data.initialized = true;
          current.updateTime = now;
          data.current = {};
          angular.copy(current, data.current);
          if (caNotificationSvc.enabled) {
            caNotificationSvc.create(exchangeSvc.data[id].fetched.current.last);
          }
          $rootScope.$broadcast("tickerUpdate");
        } else {
          changed = current.last !== data.current.last || current.spread !== data.current.spread;
          if (changed) {
            current.updateTime = now;
            if (data.previous == null) {
              data.previous = {};
            }
            angular.copy(data.current, data.previous);
            angular.copy(current, data.current);
            if (caNotificationSvc.enabled) {
              caNotificationSvc.create(exchangeSvc.data[id].fetched.current.last);
            }
            $rootScope.$broadcast("tickerUpdate");
          }
        }
      }
    };
  });

  svc.factory('caTickerSvc', function($resource, $filter, poller, caSocketSvc, exchangeSvc, caCheckAndCopySvc) {
    var USDCNY, data, errorCb, myResource, name, notifyCb, pollers, _i, _len, _ref;
    USDCNY = 6.05;
    pollers = [];
    notifyCb = function(id) {
      return function(res) {
        var current;
        switch (id) {
          case "btcchina":
            current = {
              last: $filter('round')(res.ticker.last / USDCNY),
              spread: $filter('round')((res.ticker.buy - res.ticker.sell) / USDCNY)
            };
            caCheckAndCopySvc.process(id, current);
            break;
          default:
            current = {
              last: $filter('round')(res[id].rates.last),
              spread: $filter('round')(res[id].rates.bid - res[id].rates.ask)
            };
            caCheckAndCopySvc.process(id, current);
        }
      };
    };
    errorCb = function(reason) {
      throw "poller or resource failed";
      console.log(reason);
    };
    _ref = exchangeSvc.data;
    for (name in _ref) {
      data = _ref[name];
      if (data.api.type === "REST") {
        myResource = $resource(data.api.uri);
        pollers.push({
          id: name,
          item: poller.get(myResource, {
            action: 'get',
            delay: data.api.rateLimit
          })
        });
      } else {
        caSocketSvc.process(data);
      }
    }
    for (_i = 0, _len = pollers.length; _i < _len; _i++) {
      poller = pollers[_i];
      poller.item.promise.then(null, errorCb, notifyCb(poller.id));
    }
  });

  svc.factory('caSocketSvc', function($rootScope, $filter, socketFactory, caCheckAndCopySvc) {
    var unsubscribe;
    unsubscribe = {
      depthBTCUSD: {
        op: 'unsubscribe',
        channel: '24e67e0d-1cad-4cc0-9e7a-f8523ef460fe'
      },
      tradeBTC: {
        op: 'unsubscribe',
        channel: 'dbf1dee9-4f2e-4a08-8cb7-748919a71b21'
      }
    };
    return {
      process: function(data) {
        var channel, obj, socket;
        socket = socketFactory({
          ioSocket: io.connect('https://socketio.mtgox.com:443/mtgox?Currency=USD', {
            secure: true
          })
        });
        socket.forward('error');
        for (channel in unsubscribe) {
          obj = unsubscribe[channel];
          socket.send(JSON.stringify(obj));
        }
        socket.on("message", function(res) {
          var current;
          if (res.op.indexOf("subscribe") === -1 && res.channel_name.indexOf("ticker") !== -1) {
            current = {
              spread: $filter('round')(res.ticker.buy.value - res.ticker.sell.value),
              last: $filter('round')(res.ticker.last.value),
              updateTime: null,
              error: null
            };
            caCheckAndCopySvc.process(data.id, current);
          }
        });
        socket.on("socket:error", function(event, data) {
          throw "socket failed";
          console.log(event);
          console.log(data);
        });
      }
    };
  });

  svc.factory('caD3Svc', function($q, $filter) {
    var dataParser, legend;
    dataParser = function(d) {
      d.date = d3.time.format("%m/%d/%y").parse(d.date);
      d.high = +d.high;
      d.low = +d.low;
      d.close = +d.close;
      d.volume = +d.volume;
      return d;
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
      fetch: function(uri) {
        var _deferred, _startT;
        _startT = moment();
        _deferred = $q.defer();
        d3.tsv(uri, dataParser, function(err, data) {
          var _dataNested, _exchanges;
          if (err != null) {
            _deferred.reject({
              msg: "fetching failed",
              error: err,
              t: moment.duration(moment().diff(_startT), 'ms').asSeconds()
            });
          } else {
            _exchanges = Object.keys(d3.nest().key(function(d) {
              return d.exchange;
            }).rollup(function(leaves) {
              return null;
            }).map(data));
            _dataNested = d3.nest().key(function(d) {
              return d.exchange;
            }).entries(data);
            _deferred.resolve({
              msg: "fetched",
              data: _dataNested,
              keys: _exchanges,
              t: moment.duration(moment().diff(_startT), 'ms').asSeconds()
            });
          }
        });
        return _deferred.promise;
      },
      render: function(c) {
        return function(resolved) {
          var contextExchanges, focusExchanges, xMax, xMin, yMax, _deferred, _renderT, _startT, _totalT;
          _deferred = $q.defer();
          _startT = moment();
          c.color.domain(resolved.keys);
          xMin = d3.min(resolved.data, function(d) {
            return d3.min(d.values, function(d) {
              return d.date;
            });
          });
          xMax = d3.max(resolved.data, function(d) {
            return d3.max(d.values, function(d) {
              return d.date;
            });
          });
          yMax = d3.max(resolved.data, function(d) {
            return d3.max(d.values, function(d) {
              return d.close;
            });
          });
          c.x.domain([xMin, xMax]);
          c.y.domain([0, yMax]);
          c.x2.domain(c.x.domain());
          c.y2.domain(c.y.domain());
          c.focus.append("g").attr("class", "axis x1").attr("transform", "translate(0, " + c.h + ")").call(c.axisX);
          c.focus.append("g").attr("class", "axis y1").call(c.axisY).append("text").attr("class", "axis label").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", "1em").text("per Bitcoin");
          focusExchanges = c.focus.selectAll(".exchange").data(resolved.data, function(d) {
            return d.key;
          }).enter().append("g").attr("clip-path", "url(#focus-clip)").attr("class", "exchange");
          focusExchanges.append("path").attr("d", function(d) {
            return c.line(d.values);
          }).attr("data-legend", function(d) {
            return d.key;
          }).attr("class", "line focus").style("stroke", function(d) {
            return c.color(d.key);
          });
          c.focus.append("g").attr("class", "legend").attr("transform", "translate(50,30)").style("font-size", "12px").call(legend);
          c.context.append("g").attr("class", "axis x2").attr("transform", "translate(0, " + c.h2 + ")").call(c.axisX2);
          c.context.append("g").attr("class", "x brush").call(c.brush).selectAll("rect").attr("y", -6).attr("height", c.h2 + 7);
          contextExchanges = c.context.selectAll(".exchange").data(resolved.data, function(d) {
            return d.key;
          }).enter().append("g").attr("class", "exchange");
          contextExchanges.append("path").attr("class", "line").attr("d", function(d) {
            return c.line2(d.values);
          }).style("stroke", function(d) {
            return c.color(d.key);
          });
          _renderT = moment.duration(moment().diff(_startT), 'ms').asSeconds();
          console.log(resolved.t, _renderT);
          _totalT = $filter("round")(resolved.t + _renderT);
          c.infoBox.append("text").attr("dy", "1em").text("Generated by CoinArb in " + _totalT + " s.");
          _deferred.resolve();
          return _deferred.promise;
        };
      }
    };
  });

}).call(this);

//# sourceMappingURL=app-svc.map
