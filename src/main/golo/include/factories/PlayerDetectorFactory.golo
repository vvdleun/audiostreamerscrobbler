module audiostreamerscrobbler.factories.PlayerDetectorFactory

import audiostreamerscrobbler.bluos.BluOsPlayerDetector
import audiostreamerscrobbler.factories.Config

function createPlayerDetectorFactory = {
	let config = getConfig()

	let playerDetectorFactory = DynamicObject("PlayerDetectorFactory"):
		define("_config", config):
		define("createPlayerDetector", |this| -> createPlayerDetector(this: _config()))
	
	return playerDetectorFactory
}

local function createPlayerDetector = |config| {
	# At this time only BluOS players are supported...
	let playerName = config: get("player"): get("name")
	return createBluOsPlayerDetector(playerName)
}