module audiostreamerscrobbler.factories.GroupFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.groups.{FixedPlayersGroupStrategy, Group}
import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

function createGroupFactory = {
	let factory = DynamicObject("PlayerControlThreadFactory"):
		define("createGroup", |this, cbProcessEvents| -> createConfiguredGroup(cbProcessEvents))

	return factory
}

local function createConfiguredGroup = |cbProcessEvents| {
	let config = getConfig()
	let createGroupTypes = [^_createConfiguredLegacyPlayerGroup]
	foreach createGroupFunction in createGroupTypes {
		println("waaaat: " + createGroupFunction)
		let group = createGroupFunction(cbProcessEvents, config)
		if (group != null) {
			return group
		}
	}
	raise("Error in configuration: could not create a player group")
}

local function _createConfiguredLegacyPlayerGroup = |cbProcessEvents, config| {
	println("huh")
	let playerConfig = config: get("player")
	if playerConfig is null {
		return null
	}
	
	let playerTypeInConfig = playerConfig: get("type")
	
	let playerTypeId = match {
		when playerTypeInConfig == "bluos" then getPlayerTypeID(PlayerTypes.BluOs())
		when playerTypeInConfig == "musiccast" then getPlayerTypeID(PlayerTypes.MusicCast())
		otherwise raise("Unknown player type specified in configuration: '" + playerTypeInConfig + "'")
	}
	let playerName = playerConfig: get("name")
	let playerId = createPlayerId(playerTypeId, playerName)
	
	let expectedPlayers = map[[playerTypeId, [playerName]]]
	let group = _createFixedPlayerGroup(expectedPlayers, cbProcessEvents)
	
	println("blech: " + group)
	
	return group
}

local function _createFixedPlayerGroup = |expectedPlayers, cbProcessEvents| {
	let strategy = createFixedPlayersGroupStrategy(expectedPlayers, cbProcessEvents)
	let group = createGroup("Player Group", strategy)
	return group
}
