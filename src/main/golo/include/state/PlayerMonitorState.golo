module audiostreamerscrobbler.state.PlayerMonitorState

import audiostreamerscrobbler.monitor.types.MonitorStates
import audiostreamerscrobbler.state.monitor.MonitorCallLimiterDecorator
import audiostreamerscrobbler.state.StateManager
import audiostreamerscrobbler.state.types.StateStates

import java.lang.Thread
import java.time.{Instant, Duration}

let MonitorCallLimitterEnabled = monitorCallLimiterDecorator(10000)

function createPlayerMonitorState = |player| {
	let state = DynamicObject("PlayerMonitorState"):
		define("player", player):
		define("song", null):
		define("position", null):
		define("lastCall", null):
		define("run", |this| -> runMonitorPlayerState(this))
	return state
}

local function runMonitorPlayerState = |monitor| {
	let player = monitor: player()
	let playerMonitor = player: createMonitor()

	var monitorState = MonitorStates.MONITOR_PLAYER()
	while (monitorState == MonitorStates.MONITOR_PLAYER() or monitorState: isMONITOR_SONG()) {
		monitorState = runMonitorIteration(monitor, playerMonitor)
	}

	# Scrobbling state is not ready yet...
	return StateStates.HaltProgram()
}

@MonitorCallLimitterEnabled
local function runMonitorIteration = |monitor, playerMonitor| {
	let playerMonitorState = playerMonitor: monitorPlayer()
	
	if (playerMonitorState: isMONITOR_SONG()) {
		let song = playerMonitorState: Song()

		if not validateArtistAndSong(song) {
			return MonitorStates.MONITOR_PLAYER()
		}
		
		if (isSongChanged(monitor, song)) or (isSongPositionChangedByUser(monitor, song)) {
			println("Reset song...")
			resetSong(monitor, song)
	 	}

		monitor: position(song: position())
		monitor: lastCall(Instant.now())
	}
	
	return playerMonitorState
}

local function validateArtistAndSong = |song| {
	if (song is null) {
		raise("Internal error: Monitor requested to monitor song, but song was null")
	}
	
	if (isNullOrEmpty(song: artist()) or isNullOrEmpty(song: name())) {
		println("Unknown artist or song name. Ignored.")
		return false
	}
	
	return true
}

local function isSongChanged = |monitor, song| {
	let s1 = monitor: song()
	let s2 = song

	if (s1 is null) {
		return true
	}

	return [s1: artist(), s1: name(), s1: album()] != [s2: artist(), s2: name(), s2: album()]	
}

local function isSongPositionChangedByUser = |monitor, song| {
	let currentCall = Instant.now()
	let lastCall = monitor: lastCall()
	let timeDiff = Duration.between(lastCall, currentCall): getSeconds()

	let expectedPosition = monitor: position() + timeDiff
	
 	println(expectedPosition + " seconds expected vs " + song: position() + " seconds real")
	
	let isPosInRange = range(song: position() - 5_L, song: position() + 6_L): encloses(expectedPosition)
	println("In range: " + isPosInRange)
	
	return not isPosInRange
}

local function resetSong = |monitor, song| {
	println("SONG CHANGED: " + song)
	monitor: song(song)
	monitor: position(song: position())
}

local function isNullOrEmpty = |v| {
	return v is null or v: isEmpty()
}