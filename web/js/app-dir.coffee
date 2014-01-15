angular.module('app').directive 'caNumDisplay', () ->
	templateUrl: 'partials/ca-num-display.html'
#	replace: true
	transclude: true
	restrict: 'E'
	scope: # isolated scope for type only
		name: "@"
		type: "@" # bind string
#		eq: "@"
		cur: "=" # bind scope var
		pre: "="
		baseline: "="
#		show: "&" # bind func
#		diff: "&"
		diffBaseline: "&"
	link: (scope, ele, attrs) ->
		scope.show = (input, equality) ->
			!isNaN(parseFloat(input)) and isFinite(input) and Math.abs(input) > equality # only show when >= 0.01%

		scope.diff = (cur, pre, pct) ->
			if pct == true then (cur - pre) / pre * 100 else cur - pre

		scope.diffBaseline = (cur, baseline) ->
			cur - baseline if baseline?

		return