module audiostreamerscrobbler.groups.FixedPlayersGroupStrategy

import audiostreamerscrobbler.groups.BaseGroupStragegyImpl

import java.util.Collections

function createFixedPlayersGroupStrategy = |playerIds, cbProcessEvents| {
	let strategy = createBaseGroupStragegyImpl(cbProcessEvents)

	strategy:
		define("afterIdleEvent", |this, group, event| -> afterIdleEvent(this, group, event))
	
	return strategy
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
