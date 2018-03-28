module audiostreamerscrobbler.bluesound.BlueSoundPlayer

import audiostreamerscrobbler.bluesound.BlueSoundPlayerMonitor
import audiostreamerscrobbler.player.types.PlayerTypes

function createBlueSoundPlayerFactory = {
	let factory = DynamicObject("BlueSoundPlayerFactory"):
		define("createPlayer", |this, detectedPlayer| -> createBlueSoundPlayer(detectedPlayer))

	return factory
}

local function createBlueSoundPlayer = |detectedPlayer| {
	println("Creating BlueSound player...")
	
	let player = DynamicObject("BlueSoundPlayer"):
		define("_blueSound", detectedPlayer):
		define("name", detectedPlayer: name()):
		define("playerType", PlayerTypes.BLUESOUND()):
		define("createMonitor", |this| -> createBlueSoundPlayerMonitor(this))
		
	return player		
}

