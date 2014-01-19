angular.module('app').directive 'caNumDisplay', ($animate) ->
	templateUrl: 'partials/ca-num-display.html'
#	replace: true
	transclude: true
	restrict: 'E'
	scope: # isolated scope for type only
		name: "@"
		type: "@" # bind string
		cur: "=" # bind scope var
		pre: "="
		baseline: "="
		baselineBest: "="
		curId: "="
		curBaseline: "="
		preBaseline: "="
	link: (scope, ele, attrs) ->
		_numEle = angular.element(ele[0].querySelector('.ca-main'))

		scope.getBaselineNameEng = () ->
			scope.$parent.app.data[scope.baseline].displayNameEng if scope.baseline?

		scope.show = (input, equality) ->
			!isNaN(parseFloat(input)) and isFinite(input) and Math.abs(input) > equality # only show when > 0.009%

		scope.diff = (cur, pre, pct) ->
			if pct == true then (cur - pre) / pre * 100 else cur - pre

		scope.diffBaseline = (input, baseline) ->
			Math.abs(input - baseline) if input? and baseline?

		scope.$on 'tickerUpdate', () ->
			if scope.cur != scope.pre and scope.show(scope.diff(scope.cur, scope.pre, true), 0.009)
				c = 'change'
				$animate.addClass(_numEle, c, () ->
					$animate.removeClass(_numEle, c)
				)
			return

		return