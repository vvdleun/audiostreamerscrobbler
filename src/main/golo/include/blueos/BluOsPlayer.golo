module audiostreamerscrobbler.bluos.BluOsPlayer

import audiostreamerscrobbler.bluos.BluOsPlayerMonitor
import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

function createBluOsPlayerImpl = |detectedPlayer| {
	println("Creating BluOS player...")
	
	let player = DynamicObject("BluOsPlayer"):
		define("_bluOs", detectedPlayer):
		define("name", detectedPlayer: name()):
		define("playerType", PlayerTypes.BluOs()):
		define("createMonitor", |this| -> createBluOsPlayerMonitor(this))
		
	return player		
}

