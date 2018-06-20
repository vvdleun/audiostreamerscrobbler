module audiostreamerscrobbler.groups.BaseGroupStragegyImpl

import audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents

import java.util.Collections

union PlayerStatus = {
	Idle
	Playing
}

let KEY_STATE = "state"
let KEY_PLAYER = "player"

function createBaseGroupStragegyImpl = |cbProcessEvents| {
	let players = map[]

	# Some notes:
	# 1) This is one of the few objects in this program that can be overwritten
	#    by the object that creates this object instance (for example to directly
	#    provide implementations for the unimplemented methods).
	# 2) Strategies based on this implementation are most definitely not threadsafe

	let strategyImpl = DynamicObject("BaseGroupStragegyImpl"):
		define("cbProcessEvents", |this| -> cbProcessEvents):
		define("addPlayer", |this, player| -> addPlayer(this, player)):
		define("removePlayer", |this, player| -> removePlayer(this, player)):
		define("hasPlayer", |this, player| -> hasPlayer(this, player)):
		define("players", players):
		define("isPlayerInGroupPlaying", |this| -> isPlayerInGroupPlaying(this)):
		define("handleDetectedEvent", |this, group, event| -> notImplemented("handleDetectedEvent")):
		define("handleLostEvent", |this, group, event| -> notImplemented("handleLostEvent")):
		define("handlePlayingEvent", |this, group, event| -> handlePlayingEvent(this, group, event)):
		define("handleIdleEvent", |this, group, event| -> handleIdleEvent(this, group, event)):
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

local function handlePlayingEvent = |impl, group, event| {
	let player = event: player()
	if not hasPlayer(impl, player) {
		println("Group '" + group: name() + "' does not manage the '" + player: friendlyName() + "' player")
		return
	} else if (isPlayerInGroupPlaying(impl)) {
		println("A different player in this group is already playing")
		return
	}
	
	impl: players(): get(player: id()): put(KEY_STATE , PlayerStatus.Playing())
	
	_stopAllDetectors(impl)
	_stopAllMonitorsExcept(impl, player)
}

local function _stopAllDetectors = |impl| {
	let cbProcessEvents = impl: cbProcessEvents()
	let playerTypes = _getPlayerTypes(impl)
	cbProcessEvents(GroupProcessEvents.stopDetectors(playerTypes))
}

local function _stopAllMonitorsExcept = |impl, player| {
	let cbProcessEvents = impl: cbProcessEvents()
	let players = [p foreach p in _getPlayers(impl) when p: id() != player: id()]
	cbProcessEvents(GroupProcessEvents.stopMonitors(players))
}

local function _getPlayerTypes = |impl| {
	return set[p: playerType() foreach p in _getPlayers(impl)]
}

local function _getPlayers = |impl| {
	return set[m: get(KEY_PLAYER) foreach m in impl: players(): values()]
}

local function isPlayerInGroupPlaying = |impl| {
	impl: players(): entrySet(): each(|e| {
		if (e: getValue(): get(KEY_STATE): isPlaying()) {
			return true
		}
	})
	return false
}

local function handleIdleEvent = |impl, group, event| {
	let player = event: player()
	if not hasPlayer(impl, player) {
		println("Group '" + group: name() + "' does not manage the '" + player: friendlyName() + "' player")
		return
	} else if (not impl: players(): get(player: id()): get(KEY_STATE): isPlaying()) {
		println("Player is not playing anymore")
		return
	}
	
	impl: players(): get(player: id()): put(KEY_STATE , PlayerStatus.Idle())
	
	_startAllDetectorsExcept(impl, player)
}

local function _startAllDetectorsExcept = |impl, player| {
	let playerType = player: playerType()
	
	# Include detector for current player's type only when group has other players
	# of the same type. Otherwise, there is no need to start the detector of that
	# type, as the player is already being monitored.
	let allPlayerTypes = list[p: playerType() foreach p in _getPlayers(impl)]
	let multiplePlayersOfType = frequency(allPlayerTypes, playerType) > 1

	let playerTypes = set[t foreach t in allPlayerTypes]
	if (not multiplePlayersOfType) {
		playerTypes: remove(playerType)
	}
	
	let cbProcessEvents = impl: cbProcessEvents()
	cbProcessEvents(GroupProcessEvents.startDetectors(playerTypes))
}
