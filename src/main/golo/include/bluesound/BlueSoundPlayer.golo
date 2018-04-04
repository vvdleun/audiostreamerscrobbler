module audiostreamerscrobbler.bluesound.BlueSoundPlayer

import audiostreamerscrobbler.bluesound.BlueSoundPlayerMonitor
import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

function createBlueSoundPlayerImpl = |detectedPlayer| {
	println("Creating BlueSound player...")
	
	let player = DynamicObject("BlueSoundPlayer"):
		define("_blueSound", detectedPlayer):
		define("name", detectedPlayer: name()):
		define("playerType", PlayerTypes.BlueSound()):
		define("createMonitor", |this| -> createBlueSoundPlayerMonitor(this))
		
	return player		
}
