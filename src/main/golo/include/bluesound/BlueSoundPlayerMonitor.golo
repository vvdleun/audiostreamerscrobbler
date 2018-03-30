module audiostreamerscrobbler.bluesound.BlueSoundPlayerMonitor

import audiostreamerscrobbler.bluesound.BlueSoundStatusXMLParser
import audiostreamerscrobbler.monitor.types.MonitorStates
import audiostreamerscrobbler.types.Song
import audiostreamerscrobbler.utils.RequestUtils

let REQUEST_WITH_ETAG_TIMEOUT = 60

function createBlueSoundPlayerMonitor = |player| {
	let statusUrl = "http://" + player: _blueSound(): host() + ":" + player: _blueSound(): port() + "/Status"
	
	let monitor = DynamicObject("BlueSoundPlayerMonitor"):
		define("_player", |this| -> player):
		define("_statusUrl", statusUrl):
		define("_etag", null):
		define("monitorPlayer", |this| -> monitorPlayer(this))

	return monitor
}

local function monitorPlayer = |monitor| {
	let status = requestPlayerState(monitor)
	
	validateStatus(status)

	monitor: _etag(status: etag())

	if (not isPlayerPlaying(status)) {
		# Let monitor know that player is not playing a song
		return MonitorStates.MONITOR_PLAYER()
	}

	let song = convertPlayerStatusToSong(status)
	return MonitorStates.MONITOR_SONG(song)
}

local function requestPlayerState = |monitor| {
	let url = createUrl(monitor)
	# println("Requesting " + url)
	let res = doHttpGetRequest(url, |i| -> parseBlueSoundStatusXML(i))
	# println(res)
	return res
}

local function validateStatus = |status| {
	if (not status: success()) {
		# TODO create MonitorPlayer exception...
		raise("Received invalid or unknown XML")
	}
}

local function isPlayerPlaying = |status| {
	return status: state() == "play" or status: state() == "stream"
}

local function createUrl = |monitor| {
	let url = monitor: _statusUrl()
	if (monitor: _etag() != null) {
		return url + "?etag=" + monitor: _etag() + "&timeout=" + REQUEST_WITH_ETAG_TIMEOUT
	}
	return url
}

local function convertPlayerStatusToSong = |status| {
	return Song(status: name(), status: artist(), status: album(), str2int(status: secs()), str2int(status:totlen()))
}

local function str2int = |s| {
		if (s is null) {
			return null
		}
		return Integer.parseInt(s)
}