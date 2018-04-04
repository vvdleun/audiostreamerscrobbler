module audiostreamerscrobbler.states.monitor.PlayerMonitorState

import audiostreamerscrobbler.states.monitor.types.MonitorStateTypes
import audiostreamerscrobbler.states.monitor.MonitorCallLimiterDecorator
import audiostreamerscrobbler.states.scrobbler.types.ScrobblerActionTypes
import audiostreamerscrobbler.states.types.PlayerThreadStates

import java.lang.Thread
import java.time.{Instant, Duration}
import java.io.IOException

let MonitorCallLimitterEnabled = monitorCallLimiterDecorator(10000)

let POSITION_ERROR_TOLERANCE_SECONDS = 5
let LAST_FM_MINIMAL_LISTENING_SECONDS = 4 * 60

union MonitorStateActions = {
	KeepMonitoring = { ClearErrors }
	NewSong = { Song }
	NewScrobble = { Song }
	LostPlayer
}

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

local function runMonitorPlayerState = |monitorState| {
	let player = monitorState: player()
	let playerMonitor = player: createMonitor()

	var monitorAction = MonitorStateTypes.KeepMonitoring(true)
	while (monitorAction: isKeepMonitoring()) {
		monitorAction = runMonitorIteration(monitorState, playerMonitor)
	}

	if (monitorAction: isLostPlayer()) {
		return PlayerThreadStates.DetectPlayer()

	} else if (monitorAction: isNewSong() or monitorAction: isNewScrobble()) {
		let song = monitorAction: Song()
		let scrobblersAction = match {
			when (monitorAction: isNewSong()) then ScrobblerActionTypes.UpdatePlayingNow(song)
			when (monitorAction: isNewScrobble()) then ScrobblerActionTypes.Scrobble(song)
			otherwise raise "Internal error: Unknown scrobbler monitor action '" + monitorAction + "'"
		}
		return PlayerThreadStates.ScrobbleAction(scrobblersAction, monitorState)
	}

	raise "Internal error: Unknown monitor action: '" + monitorAction + "'"
}


local function runMonitorIteration = |monitorState, playerMonitor| {
	try {
		let monitorAction = _runMonitorIteration(monitorState, playerMonitor)
		if (monitorAction: isKeepMonitoring() and monitorAction: ClearErrors()) {
			# println("Resetting ioErrors")
			monitorState: ioErrors(0)
		}
		return monitorAction
	} catch(ex) {
		println("Error occurred: " + ex)
		case {
			when ex oftype IOException.class {
				let ioErrors = monitorState: ioErrors() + 1
				monitorState: ioErrors(ioErrors)
				
				println("I/O error occurred: " + ioErrors + " time(s)")
				if (ioErrors >= 3) {
					println("Giving up...")
					return MonitorStateActions.LostPlayer()
				}
			}
			otherwise {
				# println("Ignoring for now...")
				throw(ex)
			}
		}
		return MonitorStateActions.KeepMonitoring(false)
	}
}

@MonitorCallLimitterEnabled
local function _runMonitorIteration = |monitorState, playerMonitor| {
	let monitor = playerMonitor: monitorPlayer()
	
	var action = MonitorStateActions.KeepMonitoring(true)
	
	if (monitor: isMonitorSong()) {
		let song = monitor: Song()

		if isSongScrobblable(song) {
			# Update state of monitor		
			if (isSongChanged(monitorState, song)) {
				# TODO Try to determine whether previous song should be scrobbled
				# when it was not?!
				println("New song detected: " + song)
				resetSong(monitorState, song)			
				action = MonitorStateActions.NewSong(song)
			} else if (isSongPositionChangedByUser(monitorState, song)) {
				println("Song position changed by user. Reset positions.")
				resetSongPositionsOnly(monitorState, song)
			} else if (isCandidateForNewScrobble(monitorState, song)) {
				if (isNewScrobble(monitorState, song)) {
					println("NEW SCROBBLE!")
					action = MonitorStateActions.NewScrobble(song)
					monitorState: isScrobbled(true)
				}
			}

			monitorState: position(song: position())
			monitorState: lastCall(Instant.now())
		}
	}
	
	return action
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
	return (listenedSeconds >= (song: length() / 2) or (listenedSeconds >= LAST_FM_MINIMAL_LISTENING_SECONDS))
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