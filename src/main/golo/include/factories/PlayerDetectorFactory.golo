module audiostreamerscrobbler.factories.PlayerDetectorFactory

import audiostreamerscrobbler.players.bluos.BluOsPlayerDetector
import audiostreamerscrobbler.players.musiccast.MusicCastDetector
import audiostreamerscrobbler.factories.Config

let musicCastDetectorInstance = createMusicCastDetectorInstance()

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
		when playerType == "musiccast"  then musicCastDetectorInstance
		when playerType == "bluos" then createBluOsPlayerDetector(playerName)
		otherwise raise("Internal error: Unknown player type in config.json: '" + playerType + "'")
	}
	
	return detector
}

local function createMusicCastDetectorInstance = {
	# Ugly hack to fix singleton issue in SSDP handler used by MusicCast
	# A redesign is planned... Whatever you do, do not create multiple instances
	# of the MusicCastDetector...

	let config = getConfig()
	let playerConfig = config: getOrElse("player", map[])
	let playerType = playerConfig: get("type")

	if (playerType != "musiccast") {
		return null
	}	

	let playerName = playerConfig: get("name")
	return createMusicCastDetector(playerName)
}