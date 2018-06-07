module audiostreamerscrobbler.threads.PlayerControlThread

import audiostreamerscrobbler.utils.ThreadUtils

import gololang.concurrent.workers.WorkerEnvironment
import java.lang.Thread
import java.time.{Duration, Instant}
import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}

let DEAD_PLAYER_CHECK_INTERVAL = 80
let MONITOR_THREAD_KEY = "thread"
let MONITOR_ALIVE_KEY = "lastActive"

union PlayerControlThreadMsgs = {
	StartMsg
	StopMsg
	DetectedPlayerMsg = { player }
	PlayerIsAliveMsg = { player }
	LostPlayerMsg = { player }
	CheckForDeadPlayers
}

function createPlayerControlThread = |detectorThreadFactory, monitorThreadFactory, scrobblerHandler, config| {
	let isRunning = AtomicReference(AtomicBoolean(false))

	let controlThread = DynamicObject("PlayerControlThread"):
		define("_detectorThreadFactory", detectorThreadFactory):
		define("_monitorThreadFactory", monitorThreadFactory):
		define("_scrobblerHandler", scrobblerHandler):
		define("_config", config):
		define("_env", null):
		define("_port", null):
		define("_detectorThreads", null):
		define("_monitorThreads", null):
		define("_isRunning", isRunning):
		define("_aliveThread", null):
		define("start", |this| -> initAndStartPlayerControlThread(this)):
		define("stop", |this| -> stopPlayerControlThread(this))

	return controlThread
}

local function initAndStartPlayerControlThread = |controlThread| {
	if (controlThread: _env() isnt null) {
		raise("Internal error: player control thread was already running")
	}

	controlThread: _detectorThreads(map[])
	controlThread: _monitorThreads(map[])

	let env = WorkerEnvironment.builder(): withSingleThreadExecutor() 
	let port = env: spawn(^_portIncomingMsgHandler: bindTo(controlThread))

	controlThread: _env(env)
	controlThread: _port(port)

	let aliveThread = _createAndRunPlayerAliveCheckThread(controlThread)
	controlThread: _aliveThread(aliveThread)

	port: send(PlayerControlThreadMsgs.StartMsg())
}

local function _createAndRunPlayerAliveCheckThread = |controlThread| {
	return runInNewThread("PlayersAliveCheckThread", {
		let isRunning = -> controlThread: _isRunning(): get()
		
		isRunning(): set(true)
		while (isRunning(): get()) {
			Thread.sleep(DEAD_PLAYER_CHECK_INTERVAL * 1000_L)
			controlThread: _port(): send(PlayerControlThreadMsgs.CheckForDeadPlayers())
		}
		
		controlThread: _aliveThread(null)
	})
}

local function stopPlayerControlThread = |controlThread| {
	controlThread: _isRunning(): get(): set(false)

	controlThread: _port(): send(PlayerControlThreadMsgs.StopMsg())
}

# Port message handler

local function _portIncomingMsgHandler = |controlThread, msg| {
	case {
		when msg: isStartMsg() {
			_startThreads(controlThread)
		}
		when msg: isStopMsg() {
			_stopThreads(controlThread)
		}
		when msg: isDetectedPlayerMsg() {
			_handleDetectedPlayer(controlThread, msg: player())
		}
		when msg: isPlayerIsAliveMsg() {
			_registerPlayerAlive(controlThread: _monitorThreads(), msg: player())
		}
		when msg: isCheckForDeadPlayers() {
			_checkAndScheduleDeadPlayersRemoval(controlThread)
		}
		when msg: isLostPlayerMsg() {
			_handleLostPlayer(controlThread, msg: player())
		}
		otherwise {
			raise("Internal error, received unknown message: " + msg)
		}
	}
}

# Functions that should be called via _portIncomingMsgHandler (direct or indirectly) only

local function _startThreads = |controlThread| {
	_startDetector(controlThread)
}

local function _startDetector = |controlThread| {
	let detectorThreadFactory = controlThread: _detectorThreadFactory()
	let detectorThread = detectorThreadFactory: createDetectorThread(|p| {
		controlThread: _port(): send(PlayerControlThreadMsgs.DetectedPlayerMsg(p))
	})
	let playerType = detectorThread: playerType()
	controlThread: _detectorThreads(): put(playerType, detectorThread)
	detectorThread: start()
}

local function _stopThreads = |controlThread| {
	# TODO stop running detectors
	
	# TODO stop running monitors

	controlThread: _env(): shutdown()
	controlThread: _env(null)
	controlThread: _port(null)
}

local function _handleDetectedPlayer = |controlThread, player| {
	println("Detected player: " + player: friendlyName())
	if (not _isPlayerKnown(controlThread, player) or not _isPlayerDetecting(controlThread, player)) {
		return
	}
	_removeAndStopDetector(controlThread, player)
	_addAndStartMonitorThread(controlThread, player)
}

local function _isPlayerKnown = |controlThread, player| {
	let config = controlThread: _config()
	let playerName = config: get("player"): get("name")

	if (player: name() != playerName) {
		println("Player '" + player: name() + "' is not the player we are looking for")
		return false
	}
	
	return true
}

local function _isPlayerDetecting = |controlThread, player| {
	let detectorThreads = controlThread: _detectorThreads()
	let monitorThreads = controlThread: _monitorThreads()

	let playerType = player: playerType()
	if (detectorThreads: get(playerType) is null) {
		println("Ignored: Player type '" + playerType + "' was not being detected")
		return false
	} else if (monitorThreads: get(player) isnt null) {
		println("Player '" + player: friendlyName() + "' is already being monitored")
		return false
	}
	return true
}

local function _removeAndStopDetector = |controlThread, player| {
	let detectorThreads = controlThread: _detectorThreads()
	let playerType = player: playerType()

	let detector = detectorThreads: remove(playerType)
	println("Stopping detector...")
	detector: stop()
}

local function _addAndStartMonitorThread = |controlThread, player| {
	let monitorTreadFactory = controlThread: _monitorThreadFactory()
	let scrobblerHandler = controlThread: _scrobblerHandler()
	let monitorThread = monitorTreadFactory: createMonitorThread(player, scrobblerHandler, |p| {
		# Callback that is called by PlayerMonitorThread to let us know that
		# the player is alive and well.
		controlThread: _port(): send(PlayerControlThreadMsgs.PlayerIsAliveMsg(p))
	})

	let monitorThreads = controlThread: _monitorThreads()
	monitorThreads: put(player, map[
			[MONITOR_THREAD_KEY, monitorThread],
			[MONITOR_ALIVE_KEY, null]])
	_registerPlayerAlive(monitorThreads, player)

	println("Starting monitor...")
	monitorThread: start()
}

local function _registerPlayerAlive = |monitorThreads, player| {
	let monitorThread = monitorThreads: get(player)
	if (monitorThread == null) {
		println("Internal error: player '" + player + "' is not being monitored. Cannot update alive timestamp")
		return
	}
	monitorThread: put(MONITOR_ALIVE_KEY, Instant.now())
}

local function _checkAndScheduleDeadPlayersRemoval = |controlThread| {
	println("Looking for inactive players...")
	let monitorThreads = controlThread: _monitorThreads()

	monitorThreads: entrySet(): each(|e| {
		let timeNow = Instant.now()
		let timeLastActive = e: getValue(): get(MONITOR_ALIVE_KEY)
		let timeDiff = Duration.between(timeLastActive, timeNow): getSeconds()
		if timeDiff > DEAD_PLAYER_CHECK_INTERVAL {
			let player = e: getKey()
			println("Lost player '" + player: friendlyName() + "'. Last time data was received from this player was " + timeDiff + " seconds ago.")
			controlThread: _port(): send(PlayerControlThreadMsgs.LostPlayerMsg(player))
		}
	})
	
	println("Done looking for inactive players")
}

local function _handleLostPlayer = |controlThread, player| {
	println("LOST PLAYER: " + player: friendlyName())
	if (not _isPlayerKnown(controlThread, player) or not _isPlayerMonitoring(controlThread, player)) {
		return
	}
	_removeAndStopMonitor(controlThread, player)
	_startDetector(controlThread)
}

local function _isPlayerMonitoring = |controlThread, player| {
	let detectorThreads = controlThread: _detectorThreads()
	let monitorThreads = controlThread: _monitorThreads()

	let playerType = player: playerType()
	if (detectorThreads: get(playerType) isnt null) {
		println("Internal error: player type '" + playerType + "' detection thread is already active")
		return false
	} else if (monitorThreads: get(player) is null) {
		println("Internal error: player '" + player: friendlyName() + "' monitoring thread is not active")
		return false
	}
	return true
}

local function _removeAndStopMonitor = |controlThread, player| {
	let monitorThreads = controlThread: _monitorThreads()

	let monitorThreadData = monitorThreads: remove(player)

	let monitorThread = monitorThreadData: get(MONITOR_THREAD_KEY)
	monitorThread: stop()
}
