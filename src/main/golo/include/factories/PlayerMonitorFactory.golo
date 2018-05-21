module audiostreamerscrobbler.factories.PlayerMonitorFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.factories.RequestFactory
import audiostreamerscrobbler.players.bluos.BluOsPlayerMonitor
import audiostreamerscrobbler.players.musiccast.MusicCastPlayerMonitor

function createPlayerMonitorFactory = {
	let playerMonitorFactory = DynamicObject("PlayerMonitorFactory"):
		define("createPlayerMonitor", |this, player, cb| -> createPlayerMonitor(player, cb))
	
	return playerMonitorFactory
}

local function createPlayerMonitor = |player, cb| {
	let httpRequestFactory = createHttpRequestFactory()
	
	let playerType = player: playerType()

	let playerMonitor = match {
		when playerType: isBluOs() then createBluOsPlayerMonitor(player, httpRequestFactory, cb)
		when playerType: isMusicCast() then createMusicCastPlayerMonitor(player, httpRequestFactory)
		otherwise raise("Internal error: unknown player: " + player)
	}
	
	return playerMonitor
}