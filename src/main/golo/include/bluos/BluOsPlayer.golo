module audiostreamerscrobbler.bluos.BluOsPlayer

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

function createBluOsPlayerImpl = |blueOsImpl| {
	println("Creating BluOS player...")
	
	let playerImpl = DynamicObject("BluOsPlayerImpl"):
		define("name", blueOsImpl: name()):
		define("playerType", PlayerTypes.BluOs(blueOsImpl))
		
	return playerImpl		
}

