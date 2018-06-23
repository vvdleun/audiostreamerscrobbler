module audiostreamerscrobbler.groups.FixedPlayersGroupStrategy

import audiostreamerscrobbler.groups.BaseGroupStragegyImpl
import audiostreamerscrobbler.maintypes.Player

import java.util.Collections

function createFixedPlayersGroupStrategy = |expectedPlayers, cbProcessEvents| {
	let strategy = createBaseGroupStragegyImpl(cbProcessEvents)

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
		return
	}
		
	println("Player '" + player: id() + "' is managed by the '" + group: name() + "' group. Adding player.")
	impl: addPlayer(player)
	
	# When all players of the same type in this group have been found, there's no need to
	# look for more players of this type
	let playerIds = impl: _expectedPlayers(): get(playerTypeId)
	let activePlayerIds = set[p: id() foreach p in impl: allPlayers() when p: playerTypeId() == playerTypeId]
	if (playerIds: size() == activePlayerIds: size()) {
		println("All players of type '" + playerTypeId + "' in group '" + group: name() + "' have been found. Stop looking for other players of this type.")
		impl: stopDetectors(|t| -> t: playerTypeId() == playerTypeId)
	} else {
		println("Not all players of type '" + playerTypeId + "' in group '" + group: name() + "' have been found yet. Keep looking for other players of this type")
	}
}

local function handleLostEvent = |impl, group, event| {
	let player = event: player()

	if (not _isPlayerKnown(impl, group, player)) {
		return
	}

	println("Player '" + player: id() + "' is managed by the '" + group: name() + "' group. Removing player and start looking for it")
	
	impl: startDetectors(|t| -> t: playerTypeId() == player: playerTypeId())
	impl: removePlayer(player)
}

local function _isPlayerKnown = |impl, group, player| {
	let playerId = player: id()
	let playerIds = _getPlayerIds(impl)
	
	if (not playerIds: contains(playerId)) {
		println("Player '" + playerId + "' is not managed by the '" + group: name() + "' group")
		return false
	}

	return true
}

local function _getPlayerIds = |impl| {
	let ids = set[]
	
	foreach playerTypePlayerIds in impl: _expectedPlayers(): values() {
		ids: addAll(playerTypePlayerIds)
	}
	
	return ids
}

local function afterIdleEvent = |impl, group, event| {
	let player = event: player()
	startAllDetectorsExceptForPlayer(impl, player)
}

local function startAllDetectorsExceptForPlayer = |impl, player| {
	let playerType = player: playerType()
	
	# Include detector for current player's type only when group has other players
	# of the same type. Otherwise, there is no need to start the detector of that
	# type, as the player is already being monitored.
	let allPlayerTypes = list[p: playerType() foreach p in impl: allPlayers()]
	let multiplePlayersOfType = Collections.frequency(allPlayerTypes, playerType) > 1
	
	let playerTypes = set[t foreach t in allPlayerTypes]
	if (not multiplePlayersOfType) {
		playerTypes: remove(playerType)
	}

	impl: startDetectors(|t| -> playerTypes: contains(t))
}
