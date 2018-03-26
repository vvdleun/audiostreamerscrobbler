module audiostreamerscrobbler.bluesound.BlueSoundPlayerFactory

import audiostreamerscrobbler.player.types.PlayerTypes
import audiostreamerscrobbler.utils.RequestUtils

function createBlueSoundPlayerFactory = {
	let factory = DynamicObject("BlueSoundPlayerFactory"):
		define("createPlayer", |this, detectedPlayer| -> createBlueSoundPlayer(detectedPlayer))

	return factory
}

local function createBlueSoundPlayer = |detectedPlayer| {
	println("Creating player...")
	
	let statusUrl = "http:/" + detectedPlayer: host() + ":" + detectedPlayer: port() + "/Status"
	
	let player = DynamicObject("BlueSoundPlayer"):
		define("_statusUrl", statusUrl):
		define("_bluesound", detectedPlayer):
		define("name", detectedPlayer: name()):
		define("playerType", PlayerTypes.BLUESOUND()):
		define("monitorPlayer", |this| -> monitorPlayer(this: _statusUrl()))
	return player		
}

local function monitorPlayer = |statusUrl| {
	println("Requesting " + statusUrl + "...")
	println(doHttpGetRequestAndReturnAsText(statusUrl))
	return false
}