module audiostreamerscrobbler.players.heos.HeosMonitor

import audiostreamerscrobbler.players.heos.HeosConnectionSingleton

import java.util.concurrent.atomic.AtomicBoolean

let DEBUG = true
let CMD_EVENT_STATE_CHANGED = "event/player_state_changed"
let CMD_EVENT_NOW_PLAYING_CHANGED = "event/player_now_playing_changed"
let CMD_EVENT_NOW_PLAYING_PROGRESS = "event/player_now_playing_progress"
let CMD_GET_PLAYING_NOW = "player/get_now_playing_media"
let CMD_GET_PLAYER_STATE = "player/get_play_state"

function createHeosMonitor = |player, cb| {
	let heosConnection = getHeosConnectionInstance()
	let isPlaying = AtomicBoolean(false)
	
	let monitor = DynamicObject("HeosPlayerMonitor"):
		define("_cb", |this| -> cb):
		define("_heosConnection", |this| -> heosConnection):
		define("_pid", player: heosImpl(): pid(): toString()):
		define("_isPlaying", isPlaying):
		define("player", |this| -> player):
		define("start", |this| -> startMonitor(this)):
		define("stop", |this| -> stopMonitor(this))

	let heosCb = _createHeosCallback(monitor)

	monitor: define("_heosCb", |this| -> heosCb)
	
	return monitor
}

local function startMonitor = |monitor| {
	let heosConnection = monitor: _heosConnection()
	heosConnection: addCallback(monitor: _heosCb())

	_sendGetPlayerState(monitor)
	_sendGetPlayingNowCommand(monitor)
}

local function stopMonitor = |monitor| {
	let heosConnection = monitor: _heosConnection()
	heosConnection: removeCallback(monitor: _heosCb())
}

local function _createHeosCallback = |monitor| {
	let heosCb = |response| {
		if (DEBUG) {
			println("MONITOR CALLBACK: " + response)
		}

		let heos = response: get("heos")
		let cmd = heos: get("command")
		
		var values = null
		if (heos: get("message") isnt null) {
			values = _getValues(heos: get("message"))
			if (values: get("pid") is null or monitor: _pid() != values: get("pid")) {
				if (DEBUG) {
					println("DIFFERENT PLAYER")
				}
				return
			}
		}
		
		case {
			when (cmd == CMD_EVENT_STATE_CHANGED or cmd == CMD_GET_PLAYER_STATE) {
				println("STATE CHANGED")
				monitor: _isPlaying(): set(values: get("state") == "play")
			}
			when (cmd == CMD_EVENT_NOW_PLAYING_CHANGED) {
				println("SONG CHANGED")
				println(values)
				_sendGetPlayingNowCommand(monitor)
			}
			when (cmd == CMD_EVENT_NOW_PLAYING_PROGRESS) {
				println("SONG PROGRESSING")
				println(values)
			}
			otherwise {
			}
		}
	}
	return heosCb
}

local function _getValues = |msg| {
	let keyValuePairs = msg: split("&")
	let values = map[]
	foreach (keyValuePair in keyValuePairs) {
		let keyValue = keyValuePair: split("=", 2)
		values: put(keyValue: get(0), keyValue: get(1): toString())
	}
	return values
}

local function _sendGetPlayerState = |monitor| {
	let heosConnection = monitor: _heosConnection()
	let pid = monitor: _pid()
	heosConnection: sendCommand("heos://" + CMD_GET_PLAYER_STATE + "?pid=" + pid)
}

local function _sendGetPlayingNowCommand = |monitor| {
	let heosConnection = monitor: _heosConnection()
	let pid = monitor: _pid()
	heosConnection: sendCommand("heos://" + CMD_GET_PLAYING_NOW + "?pid=" + pid)
}