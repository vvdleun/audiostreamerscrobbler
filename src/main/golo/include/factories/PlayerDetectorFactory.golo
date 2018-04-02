module audiostreamerscrobbler.factories.PlayerDetectorFactory

import audiostreamerscrobbler.bluesound.BlueSoundPlayerDetector
import audiostreamerscrobbler.factories.Config

function createPlayerDetectorFactory = {
	let config = getConfig()

	let playerDetectorFactory = DynamicObject("PlayerDetectorFactory"):
		define("_config", config):
		define("createPlayerDetector", |this| -> createPlayerDetector(this: _config()))
	
	return playerDetectorFactory
}

local function createPlayerDetector = |config| {
	# At this time only BlueSound players are supported...
	let playerName = config: get("player"): get("name")
	return createBlueSoundPlayerDetector(playerName)
}