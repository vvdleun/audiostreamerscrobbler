module audiostreamerscrobbler.groups.BaseGroupStragegyImpl

import audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents

union PlayerStatus = {
	Idle
	Playing
}

let KEY_STATE = "state"
let KEY_PLAYER = "player"

function createBaseGroupStragegyImpl = |cbProcessEvents| {
	# Some notes:
	# 1) This is one of the few objects in this program that is specifically mean to
	#    be overwritten by the object that creates this object instance (for example
	#    to directly provide implementations for the unimplemented methods).
	# 2) No implementations are provided for the DetectedEvent event handler and the
	#    afterIdleEvent() function.
	# 3) Users of this implementation that do not re-implement the handleIdleEvent()
	#    function are required to provide the implementation for the afterIdleEvent
	#    function, which is called in the default handleIdleEvent() implementation.
	# 4) Strategies based on this implementation are most definitely not threadsafe
	
	let players = map[]

	let strategyImpl = DynamicObject("BaseGroupStragegyImpl"):
		define("cbProcessEvents", |this| -> cbProcessEvents):
		define("addPlayer", |this, player| -> addPlayer(this, player)):
		define("removePlayer", |this, player| -> removePlayer(this, player)):
		define("hasPlayer", |this, player| -> hasPlayer(this, player)):
		define("players", players):
		define("allPlayers", |this| -> getPlayers(this)):
		define("allPlayerTypes", |this| -> getPlayerTypes(this)):
		define("isPlayerInGroupPlaying", |this| -> isPlayerInGroupPlaying(this)):
		define("startAllDetectors", |this| -> this: startDetectors(|t| -> true)):
		define("startDetectors", |this, f| -> startDetectors(this, f)):
		define("stopAllDetectors", |this| -> this: stopDetectors(|t| -> true)):
		define("stopDetectors", |this, f| -> stopDetectors(this, f)):
		define("stopAllMonitors", |this| -> this: stopMonitors(|p| -> true)):
		define("stopMonitors", |this, f| -> stopMonitors(this, f)):
		define("handleDetectedEvent", |this, group, event| -> notImplemented("handleDetectedEvent")):
		define("handleLostEvent", |this, group, event| -> notImplemented("handleLostEvent")):
		define("handlePlayingEvent", |this, group, event| -> handlePlayingEvent(this, group, event)):
		define("afterPlayingEvent", |this, group, event| -> afterPlayingEvent(this, group, event)):
		define("handleIdleEvent", |this, group, event| -> handleIdleEvent(this, group, event)):
		define("afterIdleEvent", |this, group, event| -> notImplemented("afterIdleEvent")):
		define("event", |this, group, event| -> event(this, group, event))

	return strategyImpl
}

local function notImplemented = |m| {
	throw IllegalStateException(m + "() was not overwritten")
}

local function event = |impl, group, event| {
	case {
		when event: isDetectedEvent() {
			impl: handleDetectedEvent(impl, group, event)
		}
		when event: isLostEvent() {
			impl: handleLostEvent(impl, group, event)
		}
		when event: isPlayingEvent() {
			impl: handlePlayingEvent(impl, group, event)
		}
		when event: isIdleEvent() {
			impl: handleIdleEvent(impl, group, event)
		}
		otherwise {
			raise("Internal error: unknown group event '" + event + "'")
		}
	}
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

local function isPlayerInGroupPlaying = |impl| {
	foreach e in impl: players(): entrySet() {
		if (e: getValue(): get(KEY_STATE): isPlaying()) {
			return true
		}
	}
	return false
}

local function handlePlayingEvent = |impl, group, event| {
	let player = event: player()
	if not hasPlayer(impl, player) {
		println("Group '" + group: name() + "' does not manage the '" + player: friendlyName() + "' player")
		return false
	} else if (isPlayerInGroupPlaying(impl)) {
		println("A different player in this group is already playing")
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
		println("Player is not playing anymore")
		return false
	}
	
	impl: players(): get(player: id()): put(KEY_STATE , PlayerStatus.Idle())
	
	impl: afterIdleEvent(group, event)
	
	return true
}

local function startDetectors = |impl, f| {
	let cbProcessEvents = impl: cbProcessEvents()
	let playerTypes = [t foreach t in getPlayerTypes(impl) when f(t)]
	cbProcessEvents(GroupProcessEvents.startDetectors(playerTypes))
}

local function stopDetectors = |impl, f| {
	let cbProcessEvents = impl: cbProcessEvents()
	let playerTypes = [t foreach t in getPlayerTypes(impl) when f(t)]
	cbProcessEvents(GroupProcessEvents.stopDetectors(playerTypes))
}

local function stopMonitors = |impl, f| {
	let cbProcessEvents = impl: cbProcessEvents()
	let players = [p foreach p in getPlayers(impl) when f(p)]
	cbProcessEvents(GroupProcessEvents.stopMonitors(players))
}

# Support functions

local function getPlayerTypes = |impl| {
	return set[p: playerType() foreach p in getPlayers(impl)]
}

local function getPlayers = |impl| {
	return set[m: get(KEY_PLAYER) foreach m in impl: players(): values()]
}
