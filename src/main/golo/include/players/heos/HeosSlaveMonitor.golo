module audiostreamerscrobbler.players.heos.HeosSlaveMonitor

import audiostreamerscrobbler.maintypes.Song
import audiostreamerscrobbler.players.heos.HeosConnectionSingleton
import audiostreamerscrobbler.threads.PlayerMonitorThreadTypes.types.MonitorThreadTypes
import audiostreamerscrobbler.utils.ThreadUtils

import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}

let DEBUG = false
let IDLE_PLAYER_INTERVAL = 60

function createHeosSlaveMonitor = |heosConnection, player, cb| {
	let heosConnectionReference = AtomicReference(getHeosConnectionInstance())
	let isPlaying = AtomicBoolean(false)
	let song = AtomicReference(null)
	let duration = AtomicReference(null)
	
	let slaveMonitor = DynamicObject("HeosSlaveMonitor"):
		define("_cb", |this| -> cb):
		define("_song", song):
		define("_duration", duration):
		define("_heosConnection", |this| -> heosConnectionReference):
		define("_isPlaying", isPlaying):
		define("pid", player: heosImpl(): pid(): toString()):
		define("isPlaying", |this| -> this: _isPlaying(): get()):
		define("send", |this, cmd| -> sendPlayerCommand(this, cmd)):
		define("playerStateChange", |this, message| -> handlePlayerStateChange(this, message)):
		define("nowPlayingProgress", |this, message| -> handlePlayerNowPlayingProgress(this, message)):
		define("getPlayingNow", |this, payload| -> handleGetPlayingNow(this, payload))

	return slaveMonitor
}

local function sendPlayerCommand = |slaveMonitor, cmd| {
	let heosConnection = slaveMonitor: _heosConnection(): get()
	let pid = slaveMonitor: pid()
	heosConnection: sendCommand("heos://" + cmd + "?pid=" + pid)
}

local function handlePlayerStateChange = |slaveMonitor, message| {
	# Player state is changed.
	# {"heos": {"command": "player/get_play_state", 
	#           "result": "success",
	#           "message": "pid=XXX&state=play"}}
	# or
	# {"heos": {"command": "event/player_state_changed",
	#			"message": "pid=XXX&state=play"}}	

	let isPlaying = slaveMonitor: _isPlaying()
	isPlaying: set(message: get("state") == "play")

	# Inform MonitorThread about status
	_updateMonitorThread(slaveMonitor)
}

local function handlePlayerNowPlayingProgress = |slaveMonitor, message| {
	# Progress changed.
	# 	{"heos":	{"command": "event/player_now_playing_progress",
	#				 "message": "pid=-1465850739&cur_pos=189000&duration=235000"}}

	let duration = slaveMonitor: _duration()
	if (message: get("cur_pos") != "0") {
		# Dirty hack, HEOS 2 seems to send duration event before song change event
		duration: set(message)

		# Inform MonitorThread about status
		_updateMonitorThread(slaveMonitor)
	}
}

local function  handleGetPlayingNow = |slaveMonitor, payload| {
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

	let song = slaveMonitor: _song()
	song: set(payload)

	# Reset duration
	let duration = slaveMonitor: _duration()
	duration: set(null)

	_updateMonitorThread(slaveMonitor)
}

local function _updateMonitorThread = |slaveMonitor| {
	let cb = slaveMonitor: _cb()
	let songPayload = slaveMonitor: _song(): get()
	let duration = slaveMonitor: _duration(): get()
	let isPlaying = slaveMonitor: _isPlaying(): get()

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
