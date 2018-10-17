module audiostreamerscrobbler.players.heos.HeosMasterMonitor

import audiostreamerscrobbler.utils.ThreadUtils

import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}
import java.util.concurrent.ConcurrentHashMap

let DEBUG = false
let IDLE_PLAYER_INTERVAL = 60

# HEOS commands
let CMD_GET_PLAYER_STATE = "player/get_play_state"
let CMD_GET_PLAYING_NOW = "player/get_now_playing_media"

# HEOS incoming events
let CMD_EVENT_STATE_CHANGED = "event/player_state_changed"
let CMD_EVENT_NOW_PLAYING_CHANGED = "event/player_now_playing_changed"
let CMD_EVENT_NOW_PLAYING_PROGRESS = "event/player_now_playing_progress"

function createHeosMasterMonitor = |heosConnection| {
	let heosConnectionReference = AtomicReference(heosConnection)
	let isRunning = AtomicBoolean(false)
	let slaves = AtomicReference(ConcurrentHashMap())
	
	let masterMonitor = DynamicObject("HeosMasterMonitor"):
		define("_heosConnection", |this| -> heosConnectionReference):
		define("_isRunning", isRunning):
		define("_aliveThread", null):
		define("_slaves", slaves):
		define("start", |this| -> startMasterMonitor(this)):
		define("stop", |this| -> stopMasterMonitor(this)):
		define("addSlave", |this, slave| -> addSlaveMonitor(this, slave)):
		define("removeSlave", |this, slave| -> removeSlaveMonitor(this, slave))

	let heosCb = _createHeosCallback(masterMonitor)

	masterMonitor: define("_heosCb", |this| -> heosCb)

	return masterMonitor
}

local function startMasterMonitor = |masterMonitor| {
	let isRunning = masterMonitor: _isRunning()
	isRunning: set(true)

	let heosConnection = masterMonitor: _heosConnection(): get()
	heosConnection: addCallback(masterMonitor: _heosCb())

	let aliveThread = _createAndRunIdlePlayerHandlerThread(masterMonitor)
	masterMonitor: _aliveThread(aliveThread)
}

local function stopMasterMonitor = |masterMonitor| {
	let isRunning = masterMonitor: _isRunning()
	isRunning: set(false)

	let heosConnection = masterMonitor: _heosConnection(): get()
	heosConnection: removeCallback(masterMonitor: _heosCb())

	masterMonitor: _slaves(): get(): clear()
}

local function addSlaveMonitor = |masterMonitor, slave| {
	let slaves = masterMonitor: _slaves(): get()
	slaves: put(slave: pid(), slave)

	slave: send(CMD_GET_PLAYER_STATE)
	slave: send(CMD_GET_PLAYING_NOW)
}

local function removeSlaveMonitor = |masterMonitor, slave| {
	let slaves = masterMonitor: _slaves(): get()
	slaves: remove(slave: pid())
}

local function _createAndRunIdlePlayerHandlerThread = |masterMonitor| {
	return runInNewThread("HeosIdlePlayerHandlerThread", {
		if (DEBUG) {
			println("Starting HeosIdlePlayerHandlerThread...")
		}
		let heosConnection = masterMonitor: _heosConnection(): get()
		let isRunning = masterMonitor: _isRunning()

		while (isRunning: get()) {
			if(heosConnection: isConnected()) {
				foreach (slave in masterMonitor: _slaves(): get(): values()) {
					if(not slave: isPlaying()) {
						slave: send(CMD_GET_PLAYER_STATE)
					}
				}
			}
			Thread.sleep(IDLE_PLAYER_INTERVAL * 1000_L)
		}
		if (DEBUG) {
			println("Stopping HeosIdlePlayerHandlerThread...")
		}
	})
}

local function _createHeosCallback = |masterMonitor| {
	let heosCb = |response| {
		if (DEBUG) {
			println("MASTER MONITOR CALLBACK: " + response)
		}

		let heos = response: get("heos")
		if (heos == null) {
			println("HeosMasterMonitor received unknown response from HEOS: " +  response)
			return
		}

		let cmd = heos: get("command")

		if (heos: get("message") is null or heos: get("message"): isEmpty()) {
			if (DEBUG) {
				println("HeosMasterMonitor received non-player message")
			}
			return
		}

		let values = _getValues(heos: get("message"))
		let slaves = masterMonitor: _slaves(): get()
		if (values is null or values: get("pid") is null or not slaves: containsKey(values: get("pid"))) {
			if (DEBUG) {
				println("HeosMasterMonitor received message for unknown player")
			}
			return
		}

		let slave = slaves: get(values: get("pid"))
		
		case {
			when (cmd == CMD_EVENT_NOW_PLAYING_CHANGED) {
				slave: send(CMD_GET_PLAYING_NOW)
			}
			when (cmd == CMD_EVENT_STATE_CHANGED or cmd == CMD_GET_PLAYER_STATE) {
				slave: playerStateChange(values)
			}
			when (cmd == CMD_EVENT_NOW_PLAYING_PROGRESS) {
				slave: nowPlayingProgress(values)
			}
			when (cmd == CMD_GET_PLAYING_NOW) {
				let payload = response: get("payload")
				slave: getPlayingNow(payload)
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