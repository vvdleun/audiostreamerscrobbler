module audiostreamerscrobbler.bluesound.Exceptions

function LSDPException = |msg| {
	return createException(msg)
}

local function createException = |msg| {
	let testie = map[   
		["extends", "java.lang.RuntimeException"]
	]
	let fabric = AdapterFabric()  
	return fabric: maker(testie): newInstance(msg)


}