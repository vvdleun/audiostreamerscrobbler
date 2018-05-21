module audiostreamerscrobbler.factories.ScrobblerHandlerFactory

import audiostreamerscrobbler.factories.ScrobblersFactory
import audiostreamerscrobbler.scrobbler.ScrobblersHandler

function createScrobblerHandlerFactory = {
	let factory = DynamicObject("ScrobblerHandlerFactory"):
		define("createScrobblerHandler", |this, scrobblerErrorHandlerThread| -> createScrobblerHandlerInstance(scrobblerErrorHandlerThread))

	return factory
}

local function createScrobblerHandlerInstance = |scrobblerErrorHandlerThread| {
	let scrobblersFactory = createScrobblersFactory()
	let scrobblers = scrobblersFactory: createScrobblers()
	
	return createScrobblersHandler(scrobblers, scrobblerErrorHandlerThread)
}
