module audiostreamerscrobbler.threads.PlayerControlThread

import audiostreamerscrobbler.groups.GroupEventTypes.types.GroupEvents
import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.utils.ThreadUtils

import gololang.concurrent.workers.WorkerEnvironment
import java.lang.{InterruptedException, Thread}
import java.time.{Duration, Instant}
import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}

let DEBUG = false
let DEAD_IDLE_TIMER_INTERVAL = 20
let IDLE_PLAYER_SECONDS = 10
let DEAD_PLAYER_SECONDS = 80
let MONITOR_ALIVE_KEY = "lastActive"
let MONITOR_IDLE_KEY = "lastIdle"
let MONITOR_PLAYER_KEY = "player"
let MONITOR_THREAD_KEY = "thread"

union PlayerControlThreadMsgs = {
	StartMsg
	StopMsg
	OutgoingGroupEventMsg = { event }
	IncominggGroupProcessEventMsg = { event }
	CheckForDeadOrIdlePlayersMsg
}

union IdleStatus = {
	NonIdle
	Idle = { timestamp, sendEvent }
	IdleHandled
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
		if (DEBUG) {
			println("GROUP INCOMING PROCESS EVENT: " + e)
		}
		controlThread: _port(): send(PlayerControlThreadMsgs.IncominggGroupProcessEventMsg(e))
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
				Thread.sleep(DEAD_IDLE_TIMER_INTERVAL * 1000_L)
				controlThread: _port(): send(PlayerControlThreadMsgs.CheckForDeadOrIdlePlayersMsg())
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
			if (DEBUG) {
				println("START: " + msg)
			}
			_sendGroupEvent(controlThread, GroupEvents.InitializationEvent())
		}
		when msg: isOutgoingGroupEventMsg() {
			if (DEBUG) {
				println("OUTGOING GROUP EVENT: " + msg)
			}
			_handleOutgoingGroupEvent(controlThread, msg: event())
		}
		when msg: isIncominggGroupProcessEventMsg() {
			if (DEBUG) {
				println("INCOMING EVENT: " + msg)
			}
			_handleIncomingGroupProcessEvent(controlThread, msg: event())
		}
		when msg: isCheckForDeadOrIdlePlayersMsg() {
			if (DEBUG) {
				println("FIND DEAD OR IDLE PLAYER:  " + msg)
			}
			_findDeadOrIdlePlayers(controlThread)
		}
		when msg: isStopMsg() {
			if (DEBUG) {
				println("STOP: " + msg)
			}
			_stopThreads(controlThread)
		}
		otherwise {
			raise("Internal error, received unknown message: " + msg)
		}
	}
}

# Functions that should be called via _portIncomingMsgHandler (direct or indirectly) only

local function _sendGroupEvent = |controlThread, event| {
	controlThread: _group(): event(event)
}

local function _handleOutgoingGroupEvent = |controlThread, event| {
	if (event: isPlayingEvent() or event: isIdleEvent()) {
		let monitorThreads = controlThread: _monitorThreads()
		let player = event: player()

		# Let the AliveThread know that the player is alive and well.
		_registerPlayerAlive(monitorThreads, player)

		let sendGroupEvent = _handleOutgoingGroupIdleEvent(controlThread, event)
		if not (sendGroupEvent) {
			if (DEBUG) {
				println("Event is not sent to group")
			}
			return
		}
	}
	
	# Send event to group, so it can react accordingly
	_sendGroupEvent(controlThread, event)
}

local function _handleOutgoingGroupIdleEvent = |controlThread, event| {
	let monitorThreads = controlThread: _monitorThreads()
	let player = event: player()

	let playerData = monitorThreads: get(player: id())
	if (playerData == null) {
		if (DEBUG) {
			println("Received data for player that is not being monitored: " + player: id())
		}
		return true
	}

	if (event: isPlayingEvent()) {
		_registerPlayerNonIdle(monitorThreads, player)
	} else {
		let currentIdleStatus = playerData: get(MONITOR_IDLE_KEY)
		case {
			when currentIdleStatus: isNonIdle() {
				println("Player could potentially be idle: " + player: id())
				_registerPlayerIdle(monitorThreads, player, false)
				# Exit and do not send a group event now. The PlayerAliveCheck timer
				# should take care of it the Idle event.
				return false
			}
			when currentIdleStatus: isIdle() and currentIdleStatus: sendEvent() {
				println("Player '" + player: id() + "' will now be reported as idle")
				_registerPlayerIdleHandled(monitorThreads, player)
			} 
			when currentIdleStatus: isIdle() or currentIdleStatus: isIdleHandled() {
				# Idle event is handled by PlayerAliveCheck timer
				if (DEBUG) {
					println("We already know that player '" + player: id() + "' is idle")
				}
				return false
			}
			otherwise {
				raise("Internal error, unknown idle player event: " + currentIdleStatus)
			}
		}
	}
	return true
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
	playerTypes: each(|t| -> _addAndStartDetector(controlThread, t))
}

local function _addAndStartDetector = |controlThread, playerType| {
	let playerTypeId = playerType: playerTypeId()

	if (controlThread: _detectorThreads(): containsKey(playerTypeId)) {
		println("Detector '" + playerTypeId + "' is already running")
		return
	}
	
	println("Starting '" + playerTypeId + "' detector...")
	
	let detectorThreadFactory = controlThread: _detectorThreadFactory()
	let detectorThread = detectorThreadFactory: createDetectorThread(playerTypeId, |p| {
		# Detector player detected callback handler
		let playerDetectedEvent = GroupEvents.DetectedEvent(p)
		controlThread: _port(): send(PlayerControlThreadMsgs.OutgoingGroupEventMsg(playerDetectedEvent))
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
	println("Stopping '" + playerTypeId + "' detector...")
	detector: stop()
}

local function _startMonitors = |controlThread, players| {
	players: each(|p| -> _addAndStartMonitorThread(controlThread, p))
}

local function _addAndStartMonitorThread = |controlThread, player| {
	let monitorThreads = controlThread: _monitorThreads()

	if (monitorThreads: containsKey(player: id())) {
		println("Monitor for player is already running: '" + player: friendlyName() + "'")
		return
	}

	println("Starting '" + player: friendlyName() + "' monitor...")

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
		controlThread: _port(): send(PlayerControlThreadMsgs.OutgoingGroupEventMsg(outgoingGroupEvent))
	})

	monitorThreads: put(player: id(), map[
			[MONITOR_THREAD_KEY, monitorThread],
			[MONITOR_ALIVE_KEY, null],
			[MONITOR_IDLE_KEY, IdleStatus.IdleHandled()],
			[MONITOR_PLAYER_KEY, player]])
	_registerPlayerAlive(monitorThreads, player)

	monitorThread: start()
}

local function _registerPlayerAlive = |monitorThreads, player| {
	_registerPlayerKeyValue(monitorThreads, player, MONITOR_ALIVE_KEY, Instant.now())
}

local function _registerPlayerIdle = |monitorThreads, player, sendEvent| {
	_registerPlayerKeyValue(monitorThreads, player, MONITOR_IDLE_KEY, IdleStatus.Idle(Instant.now(), sendEvent))
}

local function _registerPlayerNonIdle = |monitorThreads, player| {
	_registerPlayerKeyValue(monitorThreads, player, MONITOR_IDLE_KEY, IdleStatus.NonIdle())
}

local function _registerPlayerIdleHandled = |monitorThreads, player| {
	_registerPlayerKeyValue(monitorThreads, player, MONITOR_IDLE_KEY, IdleStatus.IdleHandled())
}

local function _registerPlayerKeyValue = |monitorThreads, player, key, value| {
	let playerId = player: id()
	let monitorPlayerMap = monitorThreads: get(playerId)
	if (monitorPlayerMap == null) {
		if (DEBUG) {
			println("Player '" + playerId + "' is not being monitored at the moment. Not possible to update player administration")
		}
		return
	}
	monitorPlayerMap: put(key, value)
}

local function _stopMonitors = |controlThread, players| {
	players: each(|p| -> _removeAndStopMonitor(controlThread, p))
}

local function _removeAndStopMonitor = |controlThread, player| {
	println("Stopping '" + player: friendlyName() + "' monitor...")

	let monitorThreads = controlThread: _monitorThreads()

	let monitorThreadData = monitorThreads: remove(player: id())

	let monitorThread = monitorThreadData: get(MONITOR_THREAD_KEY)
	monitorThread: stop()
}

local function _findDeadOrIdlePlayers = |controlThread| {
	if (DEBUG) {
		println("\n\nLooking for inactive and/or idle players...")
	}
	let monitorThreads = controlThread: _monitorThreads()

	monitorThreads: entrySet(): each(|e| {
		if (DEBUG) {
			println("- " + e: getKey())
			println("-- Alive: " + e: getValue(): get(MONITOR_ALIVE_KEY))
			println("-- Idle : " + e: getValue(): get(MONITOR_IDLE_KEY))
			println("")
		}

		if (_hasPlayerTimeElapsed(e: getValue(): get(MONITOR_ALIVE_KEY), DEAD_PLAYER_SECONDS)) {
			let player = e: getValue(): get(MONITOR_PLAYER_KEY)
			let lostPlayerEvent = GroupEvents.LostEvent(player)
			println("Lost player '" + player: friendlyName() + "'.")
			controlThread: _port(): send(PlayerControlThreadMsgs.OutgoingGroupEventMsg(lostPlayerEvent))
			return
		} 
		
		let idleStatus = e: getValue(): get(MONITOR_IDLE_KEY)
		if (idleStatus: isIdle() and _hasPlayerTimeElapsed(idleStatus: timestamp(), IDLE_PLAYER_SECONDS)) {
			let player = e: getValue(): get(MONITOR_PLAYER_KEY)
			let idlePlayerEvent = GroupEvents.IdleEvent(player)
			println("Idle player: '" + player: friendlyName() + "'.")
			_registerPlayerIdle(monitorThreads, player, true)
			controlThread: _port(): send(PlayerControlThreadMsgs.OutgoingGroupEventMsg(idlePlayerEvent))
			return
		}
	})
	
	if (DEBUG) {
		println("Done looking for inactive and/or idle players\n\n")
	}
}

local function _hasPlayerTimeElapsed = |value, maxSeconds| {
	let timeNow = Instant.now()
	let timeDiff = Duration.between(value, timeNow): getSeconds()
	return timeDiff > maxSeconds
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
