module audiostreamerscrobbler.threads.PlayerControlThread

import audiostreamerscrobbler.utils.ThreadUtils
import audiostreamerscrobbler.groups.GroupEventTypes.types.GroupEvents

import gololang.concurrent.workers.WorkerEnvironment
import java.lang.{InterruptedException, Thread}
import java.time.{Duration, Instant}
import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}

let DEAD_PLAYER_CHECK_INTERVAL = 80
let MONITOR_ALIVE_KEY = "lastActive"
let MONITOR_PLAYER_KEY = "player"
let MONITOR_THREAD_KEY = "thread"

union PlayerControlThreadMsgs = {
	StartMsg
	StopMsg
	OutgoingGroupEvent = { event }
	IncominggGroupProcessEvent = { event }
	CheckForDeadPlayers
}

function createPlayerControlThread = |groupFactory, detectorThreadFactory, monitorThreadFactory, scrobblerHandler, config| {
	let isRunning = AtomicReference(AtomicBoolean(false))

	let controlThread = DynamicObject("PlayerControlThread"):
		define("_groupFactory", groupFactory):
		define("_detectorThreadFactory", detectorThreadFactory):
		define("_monitorThreadFactory", monitorThreadFactory):
		define("_scrobblerHandler", scrobblerHandler):
		define("_config", config):
		define("_env", null):
		define("_port", null):
		define("_group", null):
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

	let group = controlThread: _groupFactory(): createGroup(|e| {
		# Incoming group process event handler
		controlThread: _port(): send(PlayerControlThreadMsgs.IncominggGroupProcessEvent(e))
	})
	controlThread: _group(group)
	
	let aliveThread = _createAndRunPlayerAliveCheckThread(controlThread)
	controlThread: _aliveThread(aliveThread)
	
	port: send(PlayerControlThreadMsgs.StartMsg())
}

local function _createAndRunPlayerAliveCheckThread = |controlThread| {
	return runInNewThread("PlayersAliveCheckThread", {
		let isRunning = -> controlThread: _isRunning(): get()
		
		isRunning(): set(true)
		while (isRunning(): get()) {
			try {
				Thread.sleep(DEAD_PLAYER_CHECK_INTERVAL * 1000_L)
				controlThread: _port(): send(PlayerControlThreadMsgs.CheckForDeadPlayers())
			} catch (e) {
				case {
					when e oftype InterruptedException.class {				
						return
					}
					otherwise {
						throw(e)
					}
				}
			}
		}
		
		println("Stopped player alive thread check")
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
			_sendGroupEvent(controlThread, GroupEvents.InitializationEvent())
		}
		when msg: isOutgoingGroupEvent() {
			_handleOutgoingGroupEvent(controlThread, msg: event())
		}
		when msg: isIncominggGroupProcessEvent() {
			_handleIncomingGroupProcessEvent(controlThread, msg: event())
		}
		when msg: isCheckForDeadPlayers() {
			_checkAndScheduleDeadPlayersRemoval(controlThread)
		}
		when msg: isStopMsg() {
			_stopThreads(controlThread)
		}
		otherwise {
			raise("Internal error, received unknown message: " + msg)
		}
	}
}

# Functions that should be called via _portIncomingMsgHandler (direct or indirectly) only

local function _sendGroupEvent = |controlThread, event| {
	controlThread: _port(): send(event)
}

local function _handleOutgoingGroupEvent = |controlThread, event| {
	# Player events need an additional step: letting the AliveThread know
	# that the player is alive and well.
	if (event: isPlayingEvent() or event: isIdleEvent()) {
		let monitorThreads = controlThread: _monitorThreads()
		_registerPlayerAlive(monitorThreads, event: player())
	}
	_sendGroupEvent(controlThread, event)
}

local function _handleIncomingGroupProcessEvent = |controlThread, event| {
	case {
		when event: isStartDetectors() {
			_startDetectors(controlThread, event: playerTypes())
		}
		when event: isStopDetectors() {
			_stopDetectors(controlThread, event: playerTypes())
		}
		when event: isStartMonitors() {
			_startMonitors(controlThread, event: players())
		}
		when event: isStopMonitors() {
			_stopMonitors(controlThread, event: players())
		}
		otherwise {
			raise("Internal error, received unknown group process event: " + event)
		}
	}
}

local function _startDetectors = |controlThread, playerTypes| {
	playerTypes: each(|t| {
		_addAndStartDetector(controlThread, t)
	})
}

local function _addAndStartDetector = |controlThread, playerType| {
	let playerTypeId = playerType: playerTypeId()
	let detectorThreadFactory = controlThread: _detectorThreadFactory()
	let detectorThread = detectorThreadFactory: createDetectorThread(playerTypeId, |p| {
		# Detector player detected callback handler
		let playerDetectedEvent = GroupEvents.DetectedEvent(p)
		controlThread: _port(): send(PlayerControlThreadMsgs.OutgoingGroupEvent(playerDetectedEvent))
	})
	controlThread: _detectorThreads(): put(playerTypeId, detectorThread)
	detectorThread: start()
}

local function _stopDetectors = |controlThread, playerTypes| {
	playerTypes: each(|t| -> _stopAndRemoveDetector(controlThread, t))
}

local function _stopAndRemoveDetector = |controlThread, playerType| {
	let detectorThreads = controlThread: _detectorThreads()
	let playerTypeId = playerType: playerTypeId()

	let detector = detectorThreads: remove(playerTypeId)
	println("Stopping detector...")
	detector: stop()
}

local function _startMonitors = |controlThread, players| {
	players: each(|p| -> _addAndStartMonitorThread(controlThread, p))
}

local function _addAndStartMonitorThread = |controlThread, player| {
	let monitorTreadFactory = controlThread: _monitorThreadFactory()
	let scrobblerHandler = controlThread: _scrobblerHandler()
	let monitorThread = monitorTreadFactory: createMonitorThread(player, scrobblerHandler, |p, s| {
		# Monitor player update callback handler
		# Status should be MonitorThreadTypes union instance
		let outgoingGroupEvent = match {
			when s: isMonitoring() then GroupEvents.IdleEvent(p)
			when s: isPlayingSong() then GroupEvents.PlayingEvent(p)
			otherwise raise("Internal error: Unknown monitor status: '" + s + "'")
		}
		controlThread: _port(): send(PlayerControlThreadMsgs.OutgoingGroupEvent(outgoingGroupEvent))
	})

	let monitorThreads = controlThread: _monitorThreads()
	monitorThreads: put(player: id(), map[
			[MONITOR_THREAD_KEY, monitorThread],
			[MONITOR_ALIVE_KEY, null],
			[MONITOR_PLAYER_KEY, player])
	_registerPlayerAlive(monitorThreads, player)

	println("Starting monitor...")
	monitorThread: start()
}

local function _registerPlayerAlive = |monitorThreads, player| {
	let playerId = player: id()
	let monitorPlayerMap = monitorThreads: get(playerId)
	if (monitorPlayerMap == null) {
		println("Internal error: player '" + playerId + "' is not being monitored. Cannot update alive timestamp")
		return
	}
	monitorPlayerMap: put(MONITOR_ALIVE_KEY, Instant.now())
}

local function _stopMonitors = |controlThread, players| {
	players: each(|p| -> _removeAndStopMonitor(controlThread, p))
}

local function _removeAndStopMonitor = |controlThread, player| {
	let monitorThreads = controlThread: _monitorThreads()

	let monitorThreadData = monitorThreads: remove(player: id())

	let monitorThread = monitorThreadData: get(MONITOR_THREAD_KEY)
	monitorThread: stop()
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
			let lostPlayerEvent = GroupEvents.LostEvent(player)
			println("Lost player '" + player: friendlyName() + "'. Last time data was received from this player was " + timeDiff + " seconds ago.")
			controlThread: _port(): send(PlayerControlThreadMsgs.OutgoingGroupEvent(lostPlayerEvent))
		}
	})
	
	println("Done looking for inactive players")
}

local function _stopThreads = |controlThread| {
	# Stop running detector threads
	let detectorThreads = controlThread: _detectorThreads()
	let detectorPlayerTypeds = detectorThreads: keySet()
	foreach (playerTypeId in detectorPlayerTypeds) {
		let detectorThread = detectorThreads: remove(playerTypeId)
		detectorThread: stop()
	}

	# Stop running monitors
	let monitorThreads = controlThread: _monitorThreads()
	let monitorPlayerMaps = monitorThreads: valueSet()
	foreach (monitorPlayerMap in monitorPlayerMaps) {
		let player = monitorPlayerMap: get(MONITOR_PLAYER_KEY)
		_removeAndStopMonitor(player)
	}

	controlThread: _aliveThread(): interrupt()
	
	# Stop other threads
	controlThread: _env(): shutdown()
	controlThread: _env(null)
	controlThread: _port(null)
}

