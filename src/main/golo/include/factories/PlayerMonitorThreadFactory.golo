module audiostreamerscrobbler.factories.PlayerMonitorThreadFactory

import audiostreamerscrobbler.factories.PlayerMonitorFactory
import audiostreamerscrobbler.factories.ScrobblersFactory
import audiostreamerscrobbler.threads.PlayerMonitorThread

function createPlayerMonitorThreadFactory = {
	let factory = DynamicObject("PlayerMonitorThreadFactory"):
		define("createMonitorThread", |this, player, scrobblerHandler, cbPlayerAlive| {
			return createMonitorThread(player, scrobblerHandler, cbPlayerAlive)
		})

	return factory
}

local function createMonitorThread = |player, scrobblerHandler, cbPlayerAlive| {
	let monitorFactory = createPlayerMonitorFactory()

	return createPlayerMonitorThread(monitorFactory, scrobblerHandler, player, cbPlayerAlive)
}
