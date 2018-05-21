module audiostreamerscrobbler.factories.PlayerDetectorThreadFactory

import audiostreamerscrobbler.factories.PlayerDetectorFactory
import audiostreamerscrobbler.threads.PlayerDetectorThread

function createPlayerDetectorThreadFactory = {
	let factory = DynamicObject("PlayerDetectorThreadFactory"):
		define("createDetectorThread", |this, cb| -> createDetectorThread(cb))

	return factory
}

local function createDetectorThread = |cb| {
	let playerDetector = createPlayerDetectorFactory()
	return createPlayerDetectorThread(playerDetector, cb)
}
