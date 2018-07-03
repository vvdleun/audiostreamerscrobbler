module audiostreamerscrobbler.factories.PlayerDetectorThreadFactory

import audiostreamerscrobbler.factories.PlayerDetectorFactory
import audiostreamerscrobbler.threads.PlayerDetectorThread

function createPlayerDetectorThreadFactory = {
	let factory = DynamicObject("PlayerDetectorThreadFactory"):
		define("createDetectorThread", |this, playerTypeId, cb| -> createDetectorThread(playerTypeId, cb))

	return factory
}

local function createDetectorThread = |playerTypeId, cb| {
	let playerDetectorFactory = createPlayerDetectorFactory()
	return createPlayerDetectorThread(playerTypeId, playerDetectorFactory, cb)
}
