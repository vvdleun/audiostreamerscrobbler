module audiostreamerscrobbler.bluos.BluOsPlayerMonitor

import audiostreamerscrobbler.bluos.BluOsStatusXMLParser
import audiostreamerscrobbler.maintypes.Song.types.Song
import audiostreamerscrobbler.states.monitor.types.MonitorStateTypes

let REQUEST_WITH_ETAG_TIMEOUT = 60
let REQUEST_TIMEOUT = REQUEST_WITH_ETAG_TIMEOUT + 10

function createBluOsPlayerMonitor = |player, httpRequestFactory| {
	let bluOs = player: playerType(): bluOsImpl()
	let statusUrl = "http://" + bluOs: host() + ":" + bluOs: port() + "/Status"

	httpRequestFactory: timeout(REQUEST_TIMEOUT)
	let httpRequest = httpRequestFactory: createHttpRequest()
	
	let monitor = DynamicObject("BluOsPlayerMonitor"):
		define("_statusUrl", statusUrl):
		define("_etag", null):
		define("_httpRequest", |this| -> httpRequest):
		define("player", |this| -> player):
		define("monitorPlayer", |this| -> monitorPlayer(this))

	return monitor
}

local function monitorPlayer = |monitor| {
	let status = requestPlayerState(monitor)
	
	validateStatus(status)

	monitor: _etag(status: etag())

	if (not isPlayerPlaying(status)) {
		# Let monitor know that player is not playing a song
		return MonitorStateTypes.MonitorPlayer()
	}

	let song = convertPlayerStatusToSong(status)
	return MonitorStateTypes.MonitorSong(song)
}

local function requestPlayerState = |monitor| {
	let url = createUrl(monitor)

	let httpRequest = monitor: _httpRequest()
	let res = httpRequest: doHttpGetRequest(url, |i| -> parseBluOsStatusXML(i))
	
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