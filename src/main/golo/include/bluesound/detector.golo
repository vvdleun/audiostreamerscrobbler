module audiostreamerscrobbler.bluesound.Detector

import audiostreamerscrobbler.bluesound.LSDPHandler

let TIMEOUT_SECONDS = 5

struct LSDPPlayer = {
	name,
	port,
	macAddress,
	ipAddress,
	supposedlyVersion,
	host
}

function detectBlueSoundPlayers = {
	let players = list[]
	queryLSDPPlayers(TIMEOUT_SECONDS, |p, d| {
		players: add(convertLSDPAnswerToLSDPPlayer(p, d))
		return true
	})
	return players
}

function detectBlueSoundPlayers = |playerNames| {
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
	return LSDPPlayer(
		name,
		port,
		p: get("macAddress"),
		p: get("ipAddress"),
		p: get("supposedVersion"),
		d: getAddress(): toString() + ":" + port)
}