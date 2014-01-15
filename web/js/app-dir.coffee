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
		show: "&" # bind func
		diff: "&"
	link: (scope, ele, attrs) ->
		return