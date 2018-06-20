module audiostreamerscrobbler.groups.FixedPlayersGroupStrategy

import audiostreamerscrobbler.groups.BaseGroupStragegyImpl

function createFixedPlayersGroupStrategy = |playerIds, cbProcessEvents| {
	let strategy = createBaseGroupStragegyImpl(cbProcessEvents)

	# TODO implement FixedPlayerGroupStrategy behavior...
	
	return strategy
}

