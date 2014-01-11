angular.module('app').filter 'pct', () ->
	(input) ->
		return "#{Math.round(input * 100)}%" if input != 0 # don't show completion % if nothing is completed

angular.module('app').filter 'round', () ->
	(input, decimals) ->
		return Math.round(input * Math.pow(10, decimals)) / Math.pow(10, decimals)