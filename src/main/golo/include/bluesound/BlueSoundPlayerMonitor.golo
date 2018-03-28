module audiostreamerscrobbler.bluesound.BlueSoundPlayerMonitor

import audiostreamerscrobbler.bluesound.BlueSoundStatusXMLParser
import audiostreamerscrobbler.monitor.types.MonitorStates
import audiostreamerscrobbler.utils.RequestUtils

import java.lang.Thread
import java.time.{Instant, Duration}

union BlueSoundMonitorStates = {
	NotPlaying
	Playing
}

let REQUEST_WITH_ETAG_TIMEOUT = 60
let MILLISECONDS_BETWEEN_STATUS_CALLS = 5000

function createBlueSoundPlayerMonitor = |player| {
	let statusUrl = "http://" + player: _blueSound(): host() + ":" + player: _blueSound(): port() + "/Status"
	println(statusUrl)
	
	let monitor = DynamicObject("BlueSoundPlayerMonitor"):
		define("_player", |this| -> player):
		define("_statusUrl", statusUrl):
		define("_playerStatus", null):
		define("_etag", null):
		define("_lastCall", null):
		define("monitorPlayer", |this| -> monitorPlayer(this))

	# Setup monitor
	let status = doHttpGetRequest(statusUrl, |i| -> parseBlueSoundStatusXML(i))

	validateStatus(status)

	monitor: _playerStatus(status)
	monitor: _etag(status: etag())
	monitor: _lastCall(Instant.now())
	monitor: _state(getMonitorState(status))

	return monitor
}

local function ensureMonitorIsNotFlooded = |milliSeconds| -> |func| -> |args...| {
	let monitor = args: get(0)

	let currentCall = Instant.now()
	let timeDiff = Duration.between(monitor: _lastCall(), currentCall): toMillis()
	
	println("Last call was " + timeDiff + " milliseconds ago. Must delay: " + (timeDiff < milliSeconds))
	if (timeDiff < milliSeconds) {
		let waitInterval = milliSeconds - timeDiff * 1_L
		Thread.sleep(1000_L)
		return MonitorStates.MONITOR_KEEP_RUNNING()
	}

	let res = func: invoke(args)

	monitor: _lastCall(Instant.now())
	
	return res
}

@ensureMonitorIsNotFlooded(10000)
local function monitorPlayer = |monitor| {
	let statusUrl = createUrl(monitor)

	println("Requesting " + statusUrl + "...")
	let status = doHttpGetRequest(statusUrl, |i| -> parseBlueSoundStatusXML(i))

	validateStatus(status)

	monitor: _etag(status: etag())
	monitor: _state(getMonitorState(status))
	if (not monitor: _state(): isPlaying()) {
		# Not interested in player that is not playing
		println("Player is not playing..., but " + monitor: _state())
		return MonitorStates.MONITOR_KEEP_RUNNING()
	}
	
	return MonitorStates.MONITOR_KEEP_RUNNING()
}

local function validateStatus = |status| {
	if (not status: success()) {
		# TODO create MonitorPlayer exception...
		raise("Received invalid or unknown XML")
	}
}

local function getMonitorState = |status| {
	if (status: state() != "play") {
		println("wut: " + status: state())
		return BlueSoundMonitorStates.NotPlaying()
	}
	return BlueSoundMonitorStates.Playing()
}


local function createUrl = |monitor| {
	let url = monitor: _statusUrl()
	if (monitor: _etag() != null) {
		return url + "?etag=" + monitor: _etag() + "&timeout=" + REQUEST_WITH_ETAG_TIMEOUT
	}
	return url
}