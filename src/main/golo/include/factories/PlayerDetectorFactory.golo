module audiostreamerscrobbler.factories.PlayerDetectorFactory

import audiostreamerscrobbler.factories.SocketFactory
import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.players.bluos.BluOsDetector
import audiostreamerscrobbler.players.musiccast.MusicCastDetector

function createPlayerDetectorFactory = {
	let playerDetectorFactory = DynamicObject("PlayerDetectorFactory"):
		define("createPlayerDetector", |this, playerTypeId, cb| -> createPlayerDetector(playerTypeId, cb))
	
	return playerDetectorFactory
}

local function createPlayerDetector = |playerTypeId, cb| {
	let socketFactory = createSocketFactory()
	let playerType = getPlayerType(playerTypeId)

	let detector = match {
		when playerType: isBluOs() then createBluOsDetector(socketFactory, cb)
		when playerType: isMusicCast() then createMusicCastDetector(cb)
		otherwise raise("Internal error: Unknown player type in config.json: '" + playerType + "'")
	}
	
	return detector
}
