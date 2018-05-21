module audiostreamerscrobbler.factories.PlayerControlThreadFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.factories.PlayerDetectorThreadFactory
import audiostreamerscrobbler.factories.PlayerMonitorThreadFactory
import audiostreamerscrobbler.factories.ScrobblerHandlerFactory
import audiostreamerscrobbler.threads.PlayerControlThread

function createPlayerControlThreadFactory = {
	let factory = DynamicObject("PlayerControlThreadFactory"):
		define("createPlayerControlThread", |this, scrobblerErrorHandler| -> createPlayerControlThreadInstance(scrobblerErrorHandler))

	return factory
}

local function createPlayerControlThreadInstance = |scrobblerErrorHandler| {
	let config = getConfig()

	let playerDetectorThreadFactory = createPlayerDetectorThreadFactory()
	let playerMonitorThreadFactory = createPlayerMonitorThreadFactory()

	let scrobblerHandlerFactory = createScrobblerHandlerFactory()
	let scrobblerHandler = scrobblerHandlerFactory: createScrobblerHandler(scrobblerErrorHandler)

	return createPlayerControlThread(playerDetectorThreadFactory, playerMonitorThreadFactory, scrobblerHandler, config)
}
