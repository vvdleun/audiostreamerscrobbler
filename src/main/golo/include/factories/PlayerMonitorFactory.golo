module audiostreamerscrobbler.factories.PlayerMonitorFactory

import audiostreamerscrobbler.factories.{Config, RequestFactory, SocketFactory}
import audiostreamerscrobbler.players.bluos.BluOsMonitor
import audiostreamerscrobbler.players.heos.HeosMonitor
import audiostreamerscrobbler.players.musiccast.MusicCastMonitor

function createPlayerMonitorFactory = {
	let playerMonitorFactory = DynamicObject("PlayerMonitorFactory"):
		define("createPlayerMonitor", |this, player, cb| -> createPlayerMonitor(player, cb))
	
	return playerMonitorFactory
}

local function createPlayerMonitor = |player, cb| {
	let httpRequestFactory = createHttpRequestFactory()
	let socketFactory = createSocketFactory()
	
	let playerType = player: playerType()

	let playerMonitor = match {
		when playerType: isBluOs() then createBluOsMonitor(player, httpRequestFactory, cb)
		when playerType: isHeos() then createHeosMonitor(player, cb)
		when playerType: isMusicCast() then createMusicCastMonitor(player, socketFactory, httpRequestFactory, cb)
		otherwise raise("Internal error: unknown player type: " + player)
	}
	
	return playerMonitor
}