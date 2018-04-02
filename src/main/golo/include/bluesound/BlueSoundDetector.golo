module audiostreamerscrobbler.bluesound.BlueSoundPlayerDetector

import audiostreamerscrobbler.bluesound.BlueSoundPlayer
import audiostreamerscrobbler.bluesound.LSDPHandler
import audiostreamerscrobbler.states.detector.types.DetectorStateTypes
import audiostreamerscrobbler.utils.NetworkUtils

let TIMEOUT_SECONDS = 5

struct DetectedBlueSoundPlayer = {
	name,
	port,
	model,
	version,
	macAddress,
	ipAddress,
	LSDPVersionSupposedly,
	host
}

function createBlueSoundPlayerDetector = |playerName| {
	let detector = DynamicObject("BlueSoundDetector"):
		define("detectPlayer", |this| -> detectBlueSoundPlayer(playerName))
	return detector
}

local function detectBlueSoundPlayer = |playerName| {
	let players = list[]
	let inetAddresses = getBroadcastAddresses()

	queryLSDPPlayers(inetAddresses, TIMEOUT_SECONDS, |p, d| {
		let player = convertLSDPAnswerToDetectedBlueSoundPlayer(p, d)
		if (playerName != player: name()) {
			# Player is not the player that we wanted. Keep searching...
			return true
		}
		
		players: add(player)

		# We found the requested players...
		return false
	})

	if (players: isEmpty()) {
		return DetectorStateTypes.playerNotFoundKeepTrying()
	}

	let blueSoundPlayerImpl = createBlueSoundPlayerImpl(players: get(0))
	return DetectorStateTypes.playerFound(blueSoundPlayerImpl)	
}

local function convertLSDPAnswerToDetectedBlueSoundPlayer = |p, d| {
	let mainTable = p: get("tables"): get(0): get(1)
	let name = mainTable: get("name")
	let port = mainTable: get("port")

	return DetectedBlueSoundPlayer(
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