module audiostreamerscrobbler.threads.PlayerDetectorThread

import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.utils.ThreadUtils

function createPlayerDetectorThread = |playerTypeId, detectorFactory, cb| {
	let detectorThread = DynamicObject("DetectorState"):
		define("_detectorFactory", detectorFactory):
		define("_playerTypeId", playerTypeId):
		define("_detector", null):
		define("playerType", |this| -> this: _playerTypeId(): getPlayerType()):
		define("start", |this| -> this: _detector(): start()):
		define("stop", |this| -> this: _detector(): stop())

	initThread(detectorThread, cb)
		
	return detectorThread
}

local function initThread = |detectorThread, cb| {
	let detectorFactory = detectorThread: _detectorFactory()
	let playerTypeId = detectorThread: _playerTypeId()
	let detector = detectorFactory: createPlayerDetector(playerTypeId, |implPlayer|{
		let player = createPlayer(implPlayer)
		cb(player)
	})
	
	detectorThread: _detector(detector)
}
