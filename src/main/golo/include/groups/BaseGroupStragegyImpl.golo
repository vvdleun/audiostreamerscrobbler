module audiostreamerscrobbler.groups.BaseGroupStragegyImpl

import audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents

union PlayerStatus = {
	Idle
	Playing
}

let KEY_STATE = "state"
let KEY_PLAYER = "player"

function createBaseGroupStragegyImpl = |playerTypes, cbProcessEvents| {
	# Some notes:
	# 1) This is one of the few objects in this program that is specifically meant to
	#    be overwritten by the object that creates this object instance (for example
	#    to directly provide implementations for the unimplemented methods).
	# 2) No implementations are provided for the handleDetectedEvent() and handleLostEvent()
	#    event handlers and the afterIdleEvent() function.
	# 3) Users of this implementation that do not re-implement the handleIdleEvent()
	#    function are required to provide the implementation for the afterIdleEvent
	#    function, which is called in thie class' handleIdleEvent() implementation.
	# 4) Strategies based on this implementation are definitely not threadsafe
	
	let players = map[]
	let activePlayerTypes = set[]

	let strategyImpl = DynamicObject("BaseGroupStragegyImpl"):
		define("playerTypes", playerTypes):
		define("activePlayerTypes", activePlayerTypes):
		define("cbProcessEvents", |this| -> cbProcessEvents):
		define("addPlayer", |this, player| -> addPlayer(this, player)):
		define("removePlayer", |this, player| -> removePlayer(this, player)):
		define("hasPlayer", |this, player| -> hasPlayer(this, player)):
		define("players", players):
		define("activePlayers", |this| -> activePlayers(this)):
		define("playerInGroupPlaying", |this| -> playerInGroupPlaying(this)):
		define("startAllDetectors", |this| -> this: startDetectors(|t| -> true)):
		define("startDetectors", |this, f| -> startDetectors(this, f)):
		define("stopAllDetectors", |this| -> this: stopDetectors(|t| -> true)):
		define("stopDetectors", |this, f| -> stopDetectors(this, f)):
		define("startMonitors", |this, f| -> startMonitors(this, f)):
		define("stopMonitors", |this, f| -> stopMonitors(this, f)):
		define("handleInitializationEvent", |this, group, event| -> handleInitializationEvent(this, group, event)):
		define("handleDetectedEvent", |this, group, event| -> notImplemented("handleDetectedEvent")):
		define("handleLostEvent", |this, group, event| -> notImplemented("handleLostEvent")):
		define("handlePlayingEvent", |this, group, event| -> handlePlayingEvent(this, group, event)):
		define("afterPlayingEvent", |this, group, event| -> afterPlayingEvent(this, group, event)):
		define("handleIdleEvent", |this, group, event| -> handleIdleEvent(this, group, event)):
		define("afterIdleEvent", |this, group, event| -> notImplemented("afterIdleEvent")):
		define("event", |this, group, e| -> onEvent(this, group, e))

	return strategyImpl
}

local function notImplemented = |m| {
	throw IllegalStateException(m + "() was not implemented?!")
}

local function addPlayer = |impl, player| {
	impl: players(): put(player: id(), map[
			[KEY_STATE, PlayerStatus.Idle()],
			[KEY_PLAYER, player]])
}

local function removePlayer = |impl, player| {
	return impl: players(): remove(player: id())
}

local function hasPlayer = |impl, player| {
	return impl: players(): containsKey(player: id())
}

local function activePlayers = |impl| {
	return set[m: get(KEY_PLAYER) foreach m in impl: players(): values()]
}

local function playerInGroupPlaying = |impl| {
	foreach e in impl: players(): entrySet() {
		if (e: getValue(): get(KEY_STATE): isPlaying()) {
			return e: getValue(): get(KEY_PLAYER)
		}
	}
	return null
}

local function startDetectors = |impl, f| {
	let playerTypes = list[t foreach t in impl: playerTypes() when f(t)]
	_startOrStopDetectors(impl, playerTypes, |t| -> GroupProcessEvents.StartDetectors(t))
	impl: activePlayerTypes(): addAll(playerTypes)
}

local function stopDetectors = |impl, f| {
	let playerTypes = list[t foreach t in impl: activePlayerTypes() when f(t)]
	_startOrStopDetectors(impl, playerTypes, |t| -> GroupProcessEvents.StopDetectors(t))
	impl: activePlayerTypes(): removeAll(playerTypes)
}

local function _startOrStopDetectors = |impl, playerTypes, groupProcessEvent| {
	if (not playerTypes: isEmpty()) {
		let cbProcessEvents = impl: cbProcessEvents()
		cbProcessEvents(groupProcessEvent([t foreach t in playerTypes]))
	}
}

local function startMonitors = |impl, f| {
	_startOrStopMonitors(impl, f, |p| -> GroupProcessEvents.StartMonitors(p))
}

local function stopMonitors = |impl, f| {
	_startOrStopMonitors(impl, f, |p| -> GroupProcessEvents.StopMonitors(p))
}

local function _startOrStopMonitors = |impl, f, groupProcessEvent| {
	let cbProcessEvents = impl: cbProcessEvents()
	let players = [p foreach p in activePlayers(impl) when f(p)]
	if (not players: isEmpty()) {
		cbProcessEvents(groupProcessEvent(players))
	}
}

local function handleInitializationEvent = |impl, group, event| {
	impl: startAllDetectors()
}

local function handlePlayingEvent = |impl, group, event| {
	let player = event: player()
	if not hasPlayer(impl, player) {
		println("Group '" + group: name() + "' does not manage the '" + player: friendlyName() + "' player")
		return false
	}

	let playingPlayer = playerInGroupPlaying(impl)
	
	if (playingPlayer isnt null) {
		if (player: id() != playingPlayer: id()) {
			println("A different player in this group is already playing")
		}
		return false
	}
	
	impl: players(): get(player: id()): put(KEY_STATE , PlayerStatus.Playing())
	
	impl: afterPlayingEvent(group, event)

	return true
}

local function afterPlayingEvent = |impl, group, event| {
	impl: stopAllDetectors()

	let player = event: player()
	stopMonitors(impl, |p| -> p: id() != player: id())
}

local function handleIdleEvent = |impl, group, event| {
	let player = event: player()
	if not hasPlayer(impl, player) {
		println("Group '" + group: name() + "' does not manage the '" + player: friendlyName() + "' player")
		return false
	} else if (not impl: players(): get(player: id()): get(KEY_STATE): isPlaying()) {
		# println("Player is not playing")
		return false
	}
	
	impl: players(): get(player: id()): put(KEY_STATE , PlayerStatus.Idle())
	
	impl: afterIdleEvent(group, event)
	
	return true
}

local function onEvent = |impl, group, event| {
	case {
		when event: isInitializationEvent() {
			impl: handleInitializationEvent(group, event)
		}
		when event: isDetectedEvent() {
			impl: handleDetectedEvent(group, event)
		}
		when event: isLostEvent() {
			impl: handleLostEvent(group, event)
		}
		when event: isPlayingEvent() {
			impl: handlePlayingEvent(group, event)
		}
		when event: isIdleEvent() {
			impl: handleIdleEvent(group, event)
		}
		otherwise {
			raise("Internal error: unknown group event '" + event + "'")
		}
	}
}


# Support functions

local function _getActivePlayerTypes = |impl| {
	return set[p: playerType() foreach p in activePlayers(impl)]
}