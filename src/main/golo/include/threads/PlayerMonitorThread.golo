module audiostreamerscrobbler.threads.PlayerMonitorThread

import audiostreamerscrobbler.maintypes.Song

import java.time.{Duration, Instant}

let POSITION_ERROR_TOLERANCE_SECONDS = 5
let MINIMAL_LISTENING_SECONDS = 4 * 60

union MonitorStateActions = {
	WaitingForAction
	NewSong = { song }
	NewScrobble = { song }
}

function createPlayerMonitorThread = |monitorFactory, scrobblerHandler, player, cbPlayerAlive| {
	let monitorThread = DynamicObject("PlayerMonitorState"):
		define("_monitorFactory", monitorFactory):
		define("_scrobblerHandler", scrobblerHandler):
		define("_player", player):
		define("_cbPlayerAlive", |this| -> cbPlayerAlive):
		define("_monitor", null):
		define("_song", null):
		define("_lastCall", null):
		define("_position", null):
		define("_startPosition", null):
		define("_isScrobbled", false):
		define("_timeouts", 0):
		define("start", |this| -> startMonitorThread(this)):
		define("stop", |this| -> stopMonitorThread(this))

	initMonitorThread(monitorThread)
		
	return monitorThread
}

local function initMonitorThread = |monitorThread| {
	let monitorFactory = monitorThread: _monitorFactory()
	let player = monitorThread: _player()
	let monitor = monitorFactory: createPlayerMonitor(player, |monitorState| {
		# The player's monitor shares the player's current status with us.
		# With this data we can check whether we need to scrobble, update
		# playing now, or update other scrobble-related statistics, etc.
		monitorCallback(monitorThread, monitorState)
	})

	monitorThread: _monitor(monitor)
}

local function startMonitorThread = |monitorThread| {
	println("Starting monitor thread...")
	let monitor = monitorThread: _monitor()
	monitor: start()
}

local function stopMonitorThread = |monitorThread| {
	println("Stopping monitor thread...")
	let monitor = monitorThread: _monitor()
	monitor: stop()
}

local function monitorCallback = |monitorThread, monitorState| {
	# This callback function is called by the player's monitor and passes the
	# status the player to this PlayerMonitorThread.
	# println("Receiving player input: " + monitorState)

	# Let PlayerControlThread know that this player is alive and well
	let cbPlayerAlive = monitorThread: _cbPlayerAlive()
	cbPlayerAlive(monitorThread: _player())

	let monitorAction = handleMonitorState(monitorThread, monitorState)

	case {
		when monitorAction: isWaitingForAction() {
		}

		when monitorAction: isNewSong() {
			let scrobblerHandler = monitorThread: _scrobblerHandler()
			scrobblerHandler: updatePlayingNow(monitorAction: song())
		}

		when monitorAction: isNewScrobble() {
			let scrobblerHandler = monitorThread: _scrobblerHandler()
			scrobblerHandler: scrobble(monitorAction: song())
		}

		otherwise {
			raise("Unknown monitor action: " + monitorAction)
		}
	}
}

local function handleMonitorState = |monitorThread, monitorState| {
	var action = monitorAction.WaitingForAction()
	case {
		when monitorState: isMonitoring() {
		}

		when monitorState: isPlayingSong() {
			let song = monitorState: song()

			if isSongScrobblable(song) {
				# Update state of monitor		
				if (isSongChanged(monitorThread: _song(), song)) {
					# TODO Try to determine whether previous song should be scrobbled
					# when it was not?!
					println("New song: " + song: friendlyName())
					resetSong(monitorThread, song)

					action = MonitorStateActions.NewSong(song)

				} else if (isSongPositionChangedByUser(monitorThread, song)) {
					println("Song position changed by user. Reset positions.")
					resetSongPositions(monitorThread, song)

				} else if (isCandidateForNewScrobble(monitorThread, song)) {
					if (isNewScrobble(monitorThread, song)) {
						println("NEW SCROBBLE!")
						action = MonitorStateActions.NewScrobble(song)
						monitorThread: _isScrobbled(true)
					}
				}

				# Update current state
				monitorThread: _position(song: position())
				monitorThread: _lastCall(Instant.now())
			}
		}
		
		otherwise {
			raise("Internal error: Monitor returned unknown state: '" + monitorState + "'")
		}
	}

	return action
}

# Validation functions

local function isSongScrobblable = |song| {
	if (song is null) {
		raise("Internal error: Monitor requested to monitor song, but song was null")
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

local function isSongChanged = |s1, s2| {
	if (s1 is null or s2 is null) {
		return true
	}

	return [s1: artist(), s1: name(), s1: album()] != [s2: artist(), s2: name(), s2: album()]	
}

local function isSongPositionChangedByUser = |monitorThread, song| {
	let currentCall = Instant.now()
	let lastCall = monitorThread: _lastCall()
	let timeDiff = Duration.between(lastCall, currentCall): getSeconds()

	let expectedPosition = monitorThread: _position() + timeDiff

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

local function isCandidateForNewScrobble = |monitorThread, song| {
	# Is song already scrobbled?
	if (monitorThread: _isScrobbled()) {
		# println("Song is already scrobbled")
		return false
	}
	return true
}

local function isNewScrobble = |monitorThread, song| {
	let listenedSeconds = song: position() - monitorThread: _startPosition()
	# println("Listened for " + listenedSeconds + " seconds")
	return (listenedSeconds >= (song: length() / 2) or (listenedSeconds >= MINIMAL_LISTENING_SECONDS))
}

# Actions

local function resetSong = |monitorThread, song| {
	println("SONG CHANGED: " + song)
	monitorThread: _song(song)
	monitorThread: _isScrobbled(false)
	resetSongPositions(monitorThread, song)
}

local function resetSongPositions = |monitorThread, song| {
	monitorThread: _position(song: position())
	monitorThread: _startPosition(song: position())
}

# Helper functions that should probably not have been here in the first place

local function isNullOrEmpty = |v| {
	return v is null or v: isEmpty()
}