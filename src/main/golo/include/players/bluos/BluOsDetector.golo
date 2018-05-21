module audiostreamerscrobbler.players.bluos.BluOsPlayerDetector

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes
import audiostreamerscrobbler.players.bluos.BluOsPlayer
import audiostreamerscrobbler.players.bluos.LSDPHandler
import audiostreamerscrobbler.utils.NetworkUtils

let TIMEOUT_SECONDS = 5

function createBluOsPlayerDetector = |cb| {
	let lsdpHandler = createLSDPHandler()

	let detector = DynamicObject("BluOsDetector"):
		define("_lsdpHandler", |this| -> lsdpHandler):
		define("_cb", |this| -> cb):
		define("playerType", PlayerTypes.BluOs()):
		define("start", |this| -> startBluosDetector(this)):
		define("stop", |this| -> stopBluosDetector(this))

	return detector
}

local function startBluosDetector = |detector| {
	let inetAddresses = getBroadcastAddresses()
	let lsdpHandler = detector: _lsdpHandler()

	lsdpHandler: start(inetAddresses, TIMEOUT_SECONDS, |player, datagramPacket| {
		let bluOsImpl = convertLSDPAnswerToBluOsPlayerImpl(player, datagramPacket)
		let bluOsPlayer = createBluOsPlayer(bluOsImpl)
		let cb = detector: _cb()
		cb(bluOsPlayer)
	})
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
