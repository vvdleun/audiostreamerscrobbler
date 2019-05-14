module audiostreamerscrobbler.players.bluos.BluOsMonitor

import audiostreamerscrobbler.maintypes.SongType.types.Song
import audiostreamerscrobbler.players.bluos.BluOsStatusXMLParser
import audiostreamerscrobbler.players.helpers.PollBasedMonitorHelper
import audiostreamerscrobbler.threads.PlayerMonitorThreadTypes.types.MonitorThreadTypes

let REQUEST_WITH_ETAG_TIMEOUT = 60
let REQUEST_TIMEOUT = REQUEST_WITH_ETAG_TIMEOUT + 10
let MINIMAL_POLL_INTERVAL = 10

function createBluOsMonitor = |player, httpRequestFactory, cb| {
	let bluOsImpl = player: bluOsImpl()
	let statusUrl = "http://" + bluOsImpl: host() + ":" + bluOsImpl: port() + "/Status"

	httpRequestFactory: timeout(REQUEST_TIMEOUT)
	let httpRequest = httpRequestFactory: createHttpRequest()

	let poller = createPoller(player, statusUrl, httpRequest)
	let monitor = createPollBasedPlayerMonitorHelper(poller, MINIMAL_POLL_INTERVAL, cb)

	return monitor
}

local function createPoller = |player, statusUrl, httpRequest| {
	let parser = createBluOsStatusXMLParser()

	let poller = DynamicObject("BluOsPlayerMonitorPoller"):
		define("_statusUrl", statusUrl):
		define("_etag", null):
		define("_httpRequest", httpRequest):
		define("_parser", parser):
		define("player", player):
		define("poll", |this| -> pollBluOsStatus(this))

	return poller
}

local function pollBluOsStatus = |poller| {
	# println("Polling BluOs player...")
	
	let playerStatus = requestPlayerState(poller)
	
	validateStatus(playerStatus)

	poller: _etag(playerStatus: etag())

	if (isPlayerPlaying(playerStatus)) {
		let song = convertPlayerStatusToSong(playerStatus)
		return MonitorThreadTypes.PlayingSong(song)
	} else {
		return MonitorThreadTypes.Monitoring()
	}
}

local function requestPlayerState = |poller| {
	let url = createUrl(poller)

	let httpRequest = poller: _httpRequest()
	let parser = poller: _parser()
	let playerState = httpRequest: doHttpGetRequest(url, "application/xml", |i| -> parser: parse(i))
	
	return playerState
}

local function validateStatus = |status| {
	if (not status: success()) {
		raise("Received invalid or unknown XML")
	}
}

local function isPlayerPlaying = |status| {
	return status: state() == "play" or status: state() == "stream"
}

local function createUrl = |poller| {
	let url = poller: _statusUrl()
	if (poller: _etag() != null) {
		return url + "?etag=" + poller: _etag() + "&timeout=" + REQUEST_WITH_ETAG_TIMEOUT
	}
	return url
}

local function convertPlayerStatusToSong = |status| {
	return Song(status: name(), status: artist(), status: album(), status: secs(), status: totlen())
}