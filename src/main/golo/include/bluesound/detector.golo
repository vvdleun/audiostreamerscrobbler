module audiostreamerscrobbler.bluesound.Detector

import audiostreamerscrobbler.bluesound.LSDPHandler

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
	let players = detectBlueSoundPlayers(list[playerName])
	if (players: isEmpty()) {
		return null
	}
	return players: get(0)
}

local function detectBlueSoundPlayers = |playerNames| {
	let players = list[]
	queryLSDPPlayers(TIMEOUT_SECONDS, |p, d| {
		let player = convertLSDPAnswerToLSDPPlayer(p, d)
		if (not playerNames: contains(player: name())) {
			return true
		}
	
		players: add(player)
		return false
	})

	return players
}

local function convertLSDPAnswerToLSDPPlayer = |p, d| {
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
		d: getAddress(): toString() + ":" + port)
}