module audiostreamerscrobbler.bluesound.BlueSoundPlayer

import audiostreamerscrobbler.bluesound.BlueSoundPlayerDetector
import audiostreamerscrobbler.bluesound.BlueSoundPlayerMonitor
import audiostreamerscrobbler.player.Player.types.PlayerTypes

function createBlueSoundPlayerImpl = |detectedPlayer| {
	println("Creating BlueSound player...")
	
	let player = DynamicObject("BlueSoundPlayer"):
		define("_blueSound", detectedPlayer):
		define("name", detectedPlayer: name()):
		define("playerType", PlayerTypes.BLUESOUND()):
		define("createMonitor", |this| -> createBlueSoundPlayerMonitor(this)):
		define("createDetector", |this| -> createBlueSoundPlayerDetector())
		
	return player		
}

