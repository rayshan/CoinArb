angular.module('CaApp').filter 'pct', () ->
#	countDecimals = (value) ->
#		return 0 if Math.floor(value) is value
#		return value.toString().split(".")[1].length or 0

	(input) ->
		if input != 0
			if Math.abs(input) < 1
				"#{(input * 1).toFixed(2)} %"
			else if Math.abs(input) < 10
				"#{(input * 1).toFixed(1)} %"
			else "#{(input * 1).toFixed(0)} %"

angular.module('CaApp').filter 'round', () ->
	(input) ->
		return (input * 1).toFixed(2)
		# input itself isn't recognized as num, not sure why, * 1 is a lot faster than Number()

angular.module('CaApp').filter 'toArray', () ->
	(input) ->
		out = []
		for i of input
			out.push input[i]
		out