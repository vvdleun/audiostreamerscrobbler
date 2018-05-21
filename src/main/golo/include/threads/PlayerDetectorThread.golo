module audiostreamerscrobbler.threads.PlayerDetectorThread

import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.utils.ThreadUtils

function createPlayerDetectorThread = |detectorFactory, cb| {
	let detectorThread = DynamicObject("DetectorState"):
		define("_detectorFactory", detectorFactory):
		define("_detector", null):
		define("playerType", |this| -> this: _detector(): playerType()):
		define("start", |this| -> this: _detector(): start()):
		define("stop", |this| -> this: _detector(): stop())

	initThread(detectorThread, cb)
		
	return detectorThread
}

local function initThread = |detectorThread, cb| {
	let detectorFactory = detectorThread: _detectorFactory()
	let detector = detectorFactory: createPlayerDetector(|implPlayer|{
		let player = createPlayer(implPlayer)
		cb(player)
	})
	
	detectorThread: _detector(detector)
}
