angular.module('app').filter 'pct', () ->
	(input) ->
		return "#{Math.round(input * 100)}%" if input != 0 # don't show completion % if nothing is completed

angular.module('app').filter 'round', () ->
	(input) ->
		return (input * 1).toFixed(2)
		# input itself isn't recognized as num, not sure why, * 1 is a lot faster than Number()