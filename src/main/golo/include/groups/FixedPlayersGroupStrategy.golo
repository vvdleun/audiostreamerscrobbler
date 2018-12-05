module audiostreamerscrobbler.groups.FixedPlayersGroupStrategy

import audiostreamerscrobbler.groups.BaseGroupStragegyImpl
import audiostreamerscrobbler.maintypes.Player

import java.util.Collections

let DEBUG = false

function createFixedPlayersGroupStrategy = |expectedPlayers, cbProcessEvents| {
	let playerTypes = list[getPlayerType(ptid) foreach ptid in expectedPlayers: keySet()]
	
	let strategy = createBaseGroupStragegyImpl(playerTypes, cbProcessEvents)

	# Provide implementations for missing implementations in the BaseGroupStrategyImpl
	strategy:
		define("_expectedPlayers", expectedPlayers):
		define("handleDetectedEvent", |this, group, event| -> handleDetectedEvent(this, group, event)):
		define("handleLostEvent", |this, group, event| -> handleLostEvent(this, group, event)):
		define("afterIdleEvent", |this, group, event| -> afterIdleEvent(this, group, event))
	
	return strategy
}

local function handleDetectedEvent = |impl, group, event| {
	let player = event: player()
	let playerTypeId = player: playerTypeId()

	if (not _isPlayerKnown(impl, group, player)) {
		if (DEBUG) {
			println("Player '" + player: friendlyName() + "' is not known in this group")
		}
		return
	} else if (impl: hasPlayer(player)) {
		if (DEBUG) {
			println("Player '" + player: friendlyName() + "' is already managed by this group")
		}
		return
	} else if (impl: playerInGroupPlaying() != null) {
		if (DEBUG) {
			println("A player is playing. Group is not interested in a new player at this time")
		}
		return
	}
	
	println("Detected player '" + player: id() + "' is managed by the '" + group: name() + "' group.")
	impl: addPlayer(player)

	impl: startMonitors(|p| -> p: id() == player: id())
	
	if (_allExpectedPlayersOfPlayerTypeFound(impl, playerTypeId)) {
		# When all players of the same type in this group have been found, there's no need to
		# look for more players of this type
		println("All players of type '" + playerTypeId + "' in group '" + group: name() + "' have been found. Stop looking for other players of this type.")
		impl: stopDetectors(|t| -> t: playerTypeId() == playerTypeId)
	} else {
		println("Not all players of type '" + playerTypeId + "' in group '" + group: name() + "' have been found yet. Keep looking for other players of this type")
	}
}

local function _allExpectedPlayersOfPlayerTypeFound = |impl, playerTypeId| {
	let expectedPlayerTypePlayerIds = impl: _expectedPlayers(): get(playerTypeId)
	let activePlayerTypePlayerIds = set[p: id() foreach p in impl: activePlayers() when p: playerTypeId() == playerTypeId]
	return expectedPlayerTypePlayerIds: size() == activePlayerTypePlayerIds: size()
}

local function handleLostEvent = |impl, group, event| {
	let player = event: player()

	if (not _isPlayerKnown(impl, group, player)) {
		return
	}

	let playingPlayer = impl: playerInGroupPlaying()

	impl: stopMonitors(|p| -> p: id() == player: id())
	if playingPlayer != null and playingPlayer: id() == player: id() {
		# Playing player was lost. Start all detectors
		impl: startDetectors(|t| -> true)
	} else {
		# This player was not playing. Start detectors of this player type only
		impl: startDetectors(|t| -> t: playerTypeId() == player: playerTypeId())
	}

	impl: removePlayer(player)
}

local function afterIdleEvent = |impl, group, event| {
	let player = event: player()
	_startAllDetectorsExceptForPlayer(impl, player)
}

local function _startAllDetectorsExceptForPlayer = |impl, player| {
	let playerType = player: playerType()
	let playerTypeId = playerType: playerTypeId()
	
	# Include detector for current player's type only when group has other players
	# of the same type. Otherwise, there is no need to start the detector of that
	# type, as the player is already being monitored.
	let allPlayerTypeIds = _getPlayerTypeIdsPerExpectedPlayer(impl)
	let multiplePlayersOfType = Collections.frequency(allPlayerTypeIds, playerTypeId) > 1
	
	let playerTypeIds = set[id foreach id in allPlayerTypeIds]
	if (not multiplePlayersOfType) {
		playerTypeIds: remove(playerTypeId)
	}

	impl: startDetectors(|t| -> playerTypeIds: contains(t: playerTypeId()))
}

local function _isPlayerKnown = |impl, group, player| {
	let playerId = player: id()
	let expectedPlayerIds = _getExpectedPlayerIds(impl)
	
	if (not expectedPlayerIds: contains(playerId)) {
		println("Player '" + playerId + "' is not managed by the '" + group: name() + "' group")
		return false
	}

	return true
}

local function _getExpectedPlayerIds = |impl| {
	let ids = set[]
	
	foreach playerTypePlayerIds in impl: _expectedPlayers(): values() {
		ids: addAll(playerTypePlayerIds)
	}
	
	return ids
}

local function _getPlayerTypeIdsPerExpectedPlayer = |impl| {
	let playerTypes = list[]
	foreach e in impl: _expectedPlayers(): entrySet() {
		foreach p in e: value() {
			playerTypes: add(e: key())
		}
	}
	return playerTypes
}