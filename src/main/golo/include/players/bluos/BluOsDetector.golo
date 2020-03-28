module audiostreamerscrobbler.players.bluos.BluOsDetector

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes
import audiostreamerscrobbler.players.bluos.{BluOsPlayer, LSDPHandler}
import audiostreamerscrobbler.utils.NetworkUtils

let TIMEOUT_SECONDS = 5

function createBluOsDetector = |socketFactory, cb| {
	let lsdpHandler = createLsdpHandlerInstance(socketFactory, cb)
	
	let detector = DynamicObject("BluOsDetector"):
		define("_lsdpHandler", |this| -> lsdpHandler):
		define("playerType", PlayerTypes.BluOs()):
		define("start", |this| -> startBluosDetector(this)):
		define("stop", |this| -> stopBluosDetector(this))

	return detector
}

local function createLsdpHandlerInstance = |socketFactory, cb| {
	return createLSDPHandler(socketFactory, TIMEOUT_SECONDS, |player, datagramPacket| {
		let bluOsImpl = convertLSDPAnswerToBluOsPlayerImpl(player, datagramPacket)
		let bluOsPlayer = createBluOsPlayer(bluOsImpl)
		cb(bluOsPlayer)
	})
}

local function startBluosDetector = |detector| {
	let lsdpHandler = detector: _lsdpHandler()
	lsdpHandler: start()
}

local function stopBluosDetector = |detector| {
	let lsdpHandler = detector: _lsdpHandler()
	lsdpHandler: stop()
}

local function convertLSDPAnswerToBluOsPlayerImpl = |lsdpAnswer, datagramPacket| {
	let mainTable = lsdpAnswer: get("tables"): get(0): get(1)

	return BluOsPlayerImpl(
		mainTable: get("name"),
		mainTable: get("port"),
		mainTable: get("model"),
		mainTable: get("version"),
		lsdpAnswer: get("macAddress"),
		lsdpAnswer: get("ipAddress"),
		lsdpAnswer: get("lsdpVersionSupposedly"),
		datagramPacket: getAddress(): getHostAddress()
	)
}
