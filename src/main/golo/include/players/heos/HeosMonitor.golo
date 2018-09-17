module audiostreamerscrobbler.players.heos.HeosMonitor

import audiostreamerscrobbler.maintypes.Song
import audiostreamerscrobbler.players.heos.HeosConnectionSingleton
import audiostreamerscrobbler.threads.PlayerMonitorThreadTypes.types.MonitorThreadTypes
import audiostreamerscrobbler.utils.ThreadUtils

import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}

let DEBUG = false
let IDLE_PLAYER_INTERVAL = 60

# HEOS commands
let CMD_GET_PLAYER_STATE = "player/get_play_state"
let CMD_GET_PLAYING_NOW = "player/get_now_playing_media"

# HEOS incoming events
let CMD_EVENT_STATE_CHANGED = "event/player_state_changed"
let CMD_EVENT_NOW_PLAYING_CHANGED = "event/player_now_playing_changed"
let CMD_EVENT_NOW_PLAYING_PROGRESS = "event/player_now_playing_progress"

function createHeosMonitor = |player, cb| {
	let heosConnection = getHeosConnectionInstance()
	let isRunning = AtomicBoolean(false)
	let isPlaying = AtomicBoolean(false)
	let song = AtomicReference(null)
	let duration = AtomicReference(null)
	
	let monitor = DynamicObject("HeosPlayerMonitor"):
		define("_cb", |this| -> cb):
		define("_heosConnection", |this| -> heosConnection):
		define("_pid", player: heosImpl(): pid(): toString()):
		define("_isRunning", isRunning):
		define("_isPlaying", isPlaying):
		define("_song", song):
		define("_duration", duration):
		define("_aliveThread", null):
		define("player", |this| -> player):
		define("start", |this| -> startMonitor(this)):
		define("stop", |this| -> stopMonitor(this))

	let heosCb = _createHeosCallback(monitor)

	monitor: define("_heosCb", |this| -> heosCb)
	
	return monitor
}

local function startMonitor = |monitor| {
	let isRunning = monitor: _isRunning()
	isRunning: set(true)

	let heosConnection = monitor: _heosConnection()
	heosConnection: addCallback(monitor: _heosCb())

	_sendPlayerCommand(monitor, CMD_GET_PLAYER_STATE)
	_sendPlayerCommand(monitor, CMD_GET_PLAYING_NOW)
	
	let aliveThread = _createAndRunIdlePlayerHandlerThread(monitor)
	monitor: _aliveThread(aliveThread)
}

local function stopMonitor = |monitor| {
	let isRunning = monitor: _isRunning()
	isRunning: set(false)

	let heosConnection = monitor: _heosConnection()
	heosConnection: removeCallback(monitor: _heosCb())
}

local function _createAndRunIdlePlayerHandlerThread = |monitor| {
	return runInNewThread("HeosIdlePlayerHandlerThread", {
		if (DEBUG) {
			println("Starting HeosIdlePlayerHandlerThread...")
		}
		let heosConnection = monitor: _heosConnection()
		let isRunning = monitor: _isRunning()
		let isPlaying = monitor: _isPlaying()

		while (isRunning: get()) {
			if(heosConnection: isConnected() and not isPlaying: get()) {
				# When player is paused, no information is sent to program
				# To let monitor know that the player is alive, we need to poll manually
				# when player is (probably) idle.
				_sendPlayerCommand(monitor, CMD_GET_PLAYER_STATE)
			}
			Thread.sleep(IDLE_PLAYER_INTERVAL * 1000_L)
		}
		if (DEBUG) {
			println("Stopping HeosIdlePlayerHandlerThread...")
		}
	})
}

local function _createHeosCallback = |monitor| {
	let heosCb = |response| {
		if (DEBUG) {
			println("MONITOR CALLBACK: " + response)
		}

		let heos = response: get("heos")
		if (heos == null) {
			println("Monitor received unknown response from HEOS: " +  response)
			return
		}
		
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
				_handlePlayerStateChange(monitor, values)
			}
			when (cmd == CMD_EVENT_NOW_PLAYING_CHANGED) {
				_handlePlayerNowPlayingChange(monitor, values)
			}
			when (cmd == CMD_EVENT_NOW_PLAYING_PROGRESS) {
				_handlePlayerNowPlayingProgress(monitor, values)
			}
			when (cmd == CMD_GET_PLAYING_NOW) {
				let payload = response: get("payload")
				_handleGetPlayingNow(monitor, values, payload)
			}
			otherwise {
			}
		}
	}
	return heosCb
}

local function _handlePlayerStateChange = |monitor, message| {
	# Player state is changed.
	# {"heos": {"command": "player/get_play_state", 
	#           "result": "success",
	#           "message": "pid=XXX&state=play"}}
	# or
	# {"heos": {"command": "event/player_state_changed",
	#			"message": "pid=XXX&state=play"}}	

	let isPlaying = monitor: _isPlaying()
	isPlaying: set(message: get("state") == "play")

	# Inform MonitorThread about status
	_updateMonitorThread(monitor)
}

local function _handlePlayerNowPlayingChange = |monitor, message| {
	# Song has changed. Request song info.
	# {"heos": {"command": "event/player_now_playing_changed", "message": "pid=XXX"}}

	_sendPlayerCommand(monitor, CMD_GET_PLAYING_NOW)
}

local function _handlePlayerNowPlayingProgress = |monitor, message| {
	# Progress changed.
	# 	{"heos":	{"command": "event/player_now_playing_progress",
	#				 "message": "pid=-1465850739&cur_pos=189000&duration=235000"}}

	let duration = monitor: _duration()
	if (message: get("cur_pos") != "0") {
		# Dirty hack, HEOS 2 seems to send duration event before song change event
		duration: set(message)

		# Inform MonitorThread about status
		_updateMonitorThread(monitor)
	}
}

local function  _handleGetPlayingNow = |monitor, values, payload| {
	# Retrieving info song currently playing
	# {"heos":		{"command": "player/get_now_playing_media",
	#			 	 "result": "success",
	#			 	 "message": "pid=XXX"},
	#  "payload":	{"type": "song",
	#			   	 "song": "SONG TITLE",
	#			   	 "album": "ALBUM",
	#			   	 "artist": "ARTIST",
	#				 "image_url": "xxx",
	#				 "album_id": "yyy",
	#				 "mid": "zzz",
	#				 "qid": aa,
	#				 "sid": bb},
	#  "options": []}

	let song = monitor: _song()
	song: set(payload)

	# Reset duration
	let duration = monitor: _duration()
	duration: set(null)

	_updateMonitorThread(monitor)
}

local function _updateMonitorThread = |monitor| {
	let cb = monitor: _cb()
	let isPlaying = monitor: _isPlaying(): get()
	let songPayload = monitor: _song(): get()
	let duration = monitor: _duration(): get()
	
	let isSongKnown = (songPayload != null and songPayload: get("type") == "song")
	let isDurationKnown = (duration != null)

	var song = null
	if (isPlaying and isSongKnown and isDurationKnown) {
		# We should be able to construct song
		song = _convertToSong(songPayload, duration)
	}
	
	if (song != null) {
		cb(MonitorThreadTypes.PlayingSong(song))
	} else {
		cb(MonitorThreadTypes.Monitoring())
	}
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

local function _sendPlayerCommand = |monitor, cmd| {
	let heosConnection = monitor: _heosConnection()
	let pid = monitor: _pid()
	heosConnection: sendCommand("heos://" + cmd + "?pid=" + pid)
}

local function _convertToSong = |songPayload, durationMessage| {
	let title = songPayload: get("song")
	let artist = songPayload: get("artist")
	let position = durationMessage: get("cur_pos")
	let duration = durationMessage: get("duration")

	if (title is null or artist is null or position is null or duration is null) {
		return null
	}
	
	let song = Song(
		title,
		artist,
		songPayload: get("album"),
		position: toInt() / 1000,
		duration: toInt() / 1000)

	return song
}