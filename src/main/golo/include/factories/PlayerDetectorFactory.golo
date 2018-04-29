module audiostreamerscrobbler.factories.PlayerDetectorFactory

import audiostreamerscrobbler.players.bluos.BluOsPlayerDetector
import audiostreamerscrobbler.players.musiccast.MusicCastDetector
import audiostreamerscrobbler.factories.Config

function createPlayerDetectorFactory = {
	let config = getConfig()

	let playerDetectorFactory = DynamicObject("PlayerDetectorFactory"):
		define("_config", config):
		define("createPlayerDetector", |this| -> createPlayerDetector(this: _config()))
	
	return playerDetectorFactory
}

local function createPlayerDetector = |config| {
	let playerConfig = config: getOrElse("player", map[])
	let playerType = playerConfig: get("type")
	
	let playerName = playerConfig: get("name")

	let detector = match {
		when playerType == "musiccast"  then createMusicCastDetector(playerName)
		when playerType == "bluos" then createBluOsPlayerDetector(playerName)
		otherwise raise("Internal error: Unknown player type in config.json: '" + playerType + "'")
	}
	
	return detector
}