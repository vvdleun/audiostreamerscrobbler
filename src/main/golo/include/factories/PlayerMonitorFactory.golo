module audiostreamerscrobbler.factories.PlayerMonitorFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.factories.RequestFactory
import audiostreamerscrobbler.players.bluos.BluOsPlayerMonitor
import audiostreamerscrobbler.players.musiccast.MusicCastPlayerMonitor

function createPlayerMonitorFactory = {
	let playerMonitorFactory = DynamicObject("PlayerMonitorFactory"):
		define("createPlayerMonitor", |this, player| -> createPlayerMonitor(player))
	
	return playerMonitorFactory
}

local function createPlayerMonitor = |player| {
	let httpRequestFactory = createHttpRequestFactory()
	
	let playerType = player: playerType()

	return match {
		when playerType: isBluOs() then createBluOsPlayerMonitor(player, httpRequestFactory)
		when playerType: isMusicCast() then createMusicCastPlayerMonitor(player, httpRequestFactory)
		otherwise raise("Internal error: unknown player: " + player)
	}
}