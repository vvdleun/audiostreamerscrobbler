module audiostreamerscrobbler.factories.PlayerDetectorFactory

import audiostreamerscrobbler.players.bluos.BluOsDetector
import audiostreamerscrobbler.players.musiccast.MusicCastDetector
import audiostreamerscrobbler.factories.{Config, SocketFactory}

function createPlayerDetectorFactory = {
	let config = getConfig()

	let playerDetectorFactory = DynamicObject("PlayerDetectorFactory"):
		define("_config", config):
		define("createPlayerDetector", |this, cb| -> createPlayerDetector(cb, this: _config()))
	
	return playerDetectorFactory
}

local function createPlayerDetector = |cb, config| {
	let playerConfig = config: getOrElse("player", map[])
	let playerType = playerConfig: get("type")
	let socketFactory = createSocketFactory()

	let detector = match {
		when playerType == "bluos" then createBluOsDetector(socketFactory, cb)
		when playerType == "musiccast"  then createMusicCastDetector(cb)
		otherwise raise("Internal error: Unknown player type in config.json: '" + playerType + "'")
	}
	
	return detector
}
