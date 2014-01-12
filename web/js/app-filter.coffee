angular.module('app').filter 'pct', () ->
	(input) ->
		return "#{(input * 1).toFixed(2)}%" if input != 0

angular.module('app').filter 'round', () ->
	(input) ->
		return (input * 1).toFixed(2)
		# input itself isn't recognized as num, not sure why, * 1 is a lot faster than Number()