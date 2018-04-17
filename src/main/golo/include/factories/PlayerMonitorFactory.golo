module audiostreamerscrobbler.factories.PlayerMonitorFactory

import audiostreamerscrobbler.bluos.BluOsPlayerMonitor
import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.factories.RequestFactory

function createPlayerMonitorFactory = {
	let playerMonitorFactory = DynamicObject("PlayerMonitorFactory"):
		define("createPlayerMonitor", |this, player| -> createPlayerMonitor(player))
	
	return playerMonitorFactory
}

local function createPlayerMonitor = |player| {
	# At this time only BluOS players are supported...
	let httpRequestFactory = createHttpRequestFactory()

	return createBluOsPlayerMonitor(player, httpRequestFactory)
}