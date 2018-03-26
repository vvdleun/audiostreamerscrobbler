module audiostreamerscrobbler.bluesound.Detector

import audiostreamerscrobbler.bluesound.LSDPHandler
import audiostreamerscrobbler.detector.types.DetectorStates
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

function createBlueSoundDetector = {
	let detector = DynamicObject("BlueSoundDetector"):
		define("detectPlayer", |this| -> detectBlueSoundPlayer("Woonkamer C368"))
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
		return DetectorStates.DETECTOR_KEEP_RUNNING()
	}

	return DetectorStates.DETECTOR_MONITOR_PLAYER(players: get(0))	
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
		d: getAddress()
	)
}