module audiostreamerscrobbler.bluos.BluOsPlayerDetector

import audiostreamerscrobbler.bluos.BluOsPlayer
import audiostreamerscrobbler.bluos.LSDPHandler
import audiostreamerscrobbler.states.detector.MainTypes.types.DetectorStateTypes
import audiostreamerscrobbler.utils.NetworkUtils

let TIMEOUT_SECONDS = 5

struct DetectedBluOsPlayer = {
	name,
	port,
	model,
	version,
	macAddress,
	ipAddress,
	LSDPVersionSupposedly,
	host
}

function createBluOsPlayerDetector = |playerName| {
	let detector = DynamicObject("BluOsDetector"):
		define("_lsdpHandler", |this| -> createLSDPHandler()):
		define("_playerName", |this| -> playerName):
		define("detectPlayer", |this| -> detectBluOsPlayer(this: _lsdpHandler(), this: _playerName()))
	return detector
}

local function detectBluOsPlayer = |lsdpHandler, playerName| {
	let players = list[]
	let inetAddresses = getBroadcastAddresses()

	lsdpHandler: queryLSDPPlayers(inetAddresses, TIMEOUT_SECONDS, |p, d| {
		let player = convertLSDPAnswerToDetectedBluOsPlayer(p, d)
		if (playerName != player: name()) {
			# Player is not the player that we wanted. Keep searching...
			return true
		}
		
		players: add(player)

		# We found the requested players...
		return false
	})

	if (players: isEmpty()) {
		return DetectorStateTypes.PlayerNotFoundKeepTrying()
	}

	let bluOsPlayerImpl = createBluOsPlayerImpl(players: get(0))
	return DetectorStateTypes.PlayerFound(bluOsPlayerImpl)	
}

local function convertLSDPAnswerToDetectedBluOsPlayer = |p, d| {
	let mainTable = p: get("tables"): get(0): get(1)
	let name = mainTable: get("name")
	let port = mainTable: get("port")

	return DetectedBluOsPlayer(
		name,
		port,
		mainTable: get("model"),
		mainTable: get("version"),
		p: get("macAddress"),
		p: get("ipAddress"),
		p: get("lsdpVersionSupposedly"),
		d: getAddress(): getHostAddress()
	)
}