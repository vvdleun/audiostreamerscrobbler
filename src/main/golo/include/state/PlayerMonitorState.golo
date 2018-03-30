module audiostreamerscrobbler.state.PlayerMonitorState

import audiostreamerscrobbler.monitor.types.MonitorStates
import audiostreamerscrobbler.state.monitor.MonitorCallLimiterDecorator
import audiostreamerscrobbler.state.PlayerDetectorState
import audiostreamerscrobbler.state.StateManager
import audiostreamerscrobbler.state.types.StateStates

import java.lang.Thread
import java.time.{Instant, Duration}
import java.io.IOException

let MonitorCallLimitterEnabled = monitorCallLimiterDecorator(10000)

let POSITION_ERROR_TOLERANCE_SECONDS = 5
let LAST_FM_MINIMAL_LISTENING_SECONDS = 4 * 60

function createPlayerMonitorState = |player| {
	let state = DynamicObject("PlayerMonitorState"):
		define("player", player):
		define("song", null):
		define("lastCall", null):
		define("position", null):
		define("startPosition", null):
		define("isScrobbled", false):
		define("ioErrors", 0):
		define("run", |this| -> runMonitorPlayerState(this))
	return state
}

local function runMonitorPlayerState = |monitor| {
	let player = monitor: player()
	let playerMonitor = player: createMonitor()

	var monitorState = MonitorStates.MONITOR_PLAYER()
	while (_keepMonitorRunning(monitorState)) {
		monitorState = runMonitorIteration(monitor, playerMonitor)
	}

	if (monitorState: isMONITOR_LOST_PLAYER()) {
		let detector = monitorState: Player(): createDetector()
		return StateStates.NewState(createPlayerDetectorState(detector))
	}
	
	# Scrobbling state is not ready yet...
	return StateStates.HaltProgram()
}

local function _keepMonitorRunning = |monitorState| {
	return (monitorState: isMONITOR_PLAYER() or monitorState: isMONITOR_SONG() or monitorState: isMONITOR_IGNORE_ITERATION())
}

local function runMonitorIteration = |monitor, playerMonitor| {
	try {
		let monitorState = _runMonitorIteration(monitor, playerMonitor)
		if not monitorState: isMONITOR_IGNORE_ITERATION() {
			# println("Resetting ioErrors")
			monitor: ioErrors(0)
		}
		return monitorState
	} catch(ex) {
		println("Error occurred: " + ex)
		case {
			when ex oftype IOException.class {
				println("I/O exception ocurred: " + ex)
				let ioErrors = monitor: ioErrors() + 1
				monitor: ioErrors(ioErrors)
				
				println("Times occurred: " + ioErrors)
				if (ioErrors >= 3) {
					println("Giving up...")
					return MonitorStates.MONITOR_LOST_PLAYER(monitor: player())
				}
			}
			otherwise {
				throw(ex)
				println("Ignoring for now...")
			}
		}
		return monitorState.MONITOR_PLAYER()
	}
}


@MonitorCallLimitterEnabled
local function _runMonitorIteration = |monitor, playerMonitor| {
	let playerMonitorState = playerMonitor: monitorPlayer()
	
	if (playerMonitorState: isMONITOR_SONG()) {
		let song = playerMonitorState: Song()

		if not isSongScrobblable(song) {
			return MonitorStates.MONITOR_PLAYER()
		}

		# Update state of monitor
			
		if (isSongChanged(monitor, song)) {
			# TODO Try to determine whether previous song should be scrobbled
			# if it was not already?!
			println("New song: " + song)
			resetSong(monitor, song)
	 	} else if (isSongPositionChangedByUser(monitor, song)) {
			println("Song position changed by user. Reset positions.")
			resetSongPositionsOnly(monitor, song)
		} else if (isCandidateForNewScrobble(monitor, song)) {
			if (isNewScrobble(monitor, song)) {
				println("NEW SCROBBLE!")
				monitor: isScrobbled(true)
			}
		}

		monitor: position(song: position())
		monitor: lastCall(Instant.now())
	}
	
	return playerMonitorState
}

# All checks used in main loop iteration

local function isSongScrobblable = |song| {
	if (song is null) {
		raise("Internal error: Monitor requested to monitor song, but song was null")
	}

	# Artist and song title must be known
	if (isNullOrEmpty(song: artist()) or isNullOrEmpty(song: name())) {
		# println("Unknown artist or song name. Ignored.")
		return false
	}
	
	# Artist and song title must be known
	if (isNullOrEmpty(song: artist()) or isNullOrEmpty(song: name())) {
		# println("Unknown artist or song name. Ignored.")
		return false
	}

	# Position and length as well
	if (song: position() is null or song: length() is null) {
		# println("Unknown song position or song length. Ignored.")
		return false
	}

	# Is song duration long enough? (as dictated by Last FM)
	if (song: length() < 30) {
		# println("Song is too short to be scrobbled")
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

 	# println(expectedPosition + " seconds expected vs " + song: position() + " seconds real")
	
	let wasPositionModified = _isCurrentPositionModified(song: position(), expectedPosition)
	
	# println("Was position modified by user: " + wasPositionModified)
	return wasPositionModified	
}

local function _isCurrentPositionModified = |currentPosition, expectedPosition| {
	let tolerance = POSITION_ERROR_TOLERANCE_SECONDS * 1_L
	let toleranceRange = range(currentPosition - tolerance, currentPosition + tolerance + 1)
	return not toleranceRange: encloses(expectedPosition)
}

local function isCandidateForNewScrobble = |monitor, song| {
	# Is song already scrobbled?
	if (monitor: isScrobbled()) {
		# println("Song is already scrobbled")
		return false
	}
	return true
}

local function isNewScrobble = |monitor, song| {
	let listenedSeconds = song: position() - monitor: startPosition()
	println("Listened for " + listenedSeconds + " seconds")
	return (listenedSeconds > (song: length() / 2) or (listenedSeconds >= LAST_FM_MINIMAL_LISTENING_SECONDS))
}

# All actions taken in main loop iteration

local function resetSong = |monitor, song| {
	# println("SONG CHANGED: " + song)
	monitor: song(song)
	monitor: isScrobbled(false)
	resetSongPositionsOnly(monitor, song)
}

local function resetSongPositionsOnly = |monitor, song| {
	monitor: position(song: position())
	monitor: startPosition(song: position())
}

# Helper functions that should yet again probably not have been here in the first place

local function isNullOrEmpty = |v| {
	return v is null or v: isEmpty()
}