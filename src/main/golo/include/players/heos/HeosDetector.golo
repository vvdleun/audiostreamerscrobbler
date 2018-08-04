module audiostreamerscrobbler.players.heos.HeosDetector

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes
import audiostreamerscrobbler.players.heos.{HeosConnectionSingleton, HeosDeviceDescriptorXmlParser}

import java.net.URL

function createHeosDetector = |cb| {
	let heosConnection = getHeosConnectionInstance()

	let detector = DynamicObject("HeosDetector"):
		define("_heosConnection", |this| -> heosConnection):
		define("_cb", |this| -> cb):
		define("playerType", PlayerTypes.Heos()):
		define("start", |this| -> startHeosDetector(this)):
		define("stop", |this| -> stopHeosDetector(this))
		
	return detector
}

local function startHeosDetector = |detector| {
	let connection = detector: _heosConnection()
	if not (connection: isOpened()) {
		connection: open()
	}

	connection: sendCommand("get_players", |r| {
		println("pggg: " + r)
	})

	
	# connection: connectDetector({
	# })
}

local function stopHeosDetector = |detector| {
	# let connection = detector: _heosConnection()
	# connection: disconnectDetector()
}



local function _createHeosImpl = |deviceDescriptor| {
}
