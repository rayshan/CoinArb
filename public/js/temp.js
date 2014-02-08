	indexedArray = [
		{
			key: "baseline",
			values: [
				{
					date: "Jan 1 2013", // assume valid parsed date
					value: 100
				},
				{
					date: "Jan 2 2013",
					value: 150
				}
			]
		},
		{
			key: "other",
			values: [
				{
					date: "Jan 2 2013", // note dates do not line up
					value: 1000
				},
				{
					date: "Jan 3 2013",
					value: 2000
				}
			]
		},
	]

	desiredResult = [
		{
			key: "baseline",
			values: [
				{
					date: "Jan 1 2013", // assume valid parsed date
					value: 100,
					delta: 0 // 0 because it's the baseline
				},
				{
					date: "Jan 2 2013",
					value: 150,
					delta: 0
				}
			]
		},
		{
			key: "other",
			values: [
				{
					date: "Jan 2 2013",
					value: 1000,
					delta: 10 // 1000 / 100
				},
				{
					date: "Jan 3 2013", // note dates do not line up
					value: 2000,
					delta: null // null because there's no date match
				}
			]
		},
	]

associativeArray = {
	baseline: [
		{
			date: "Jan 1 2013", // assume valid parsed date
			value: 100
		},
		{
			date: "Jan 2 2013",
			value: 150
		}
	],
	other: [
		{
			date: "Jan 2 2013", // note dates do not line up
			value: 1000
		},
		{
			date: "Jan 3 2013",
			value: 2000
		}
	]
}