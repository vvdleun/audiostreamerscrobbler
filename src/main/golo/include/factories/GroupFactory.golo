module audiostreamerscrobbler.factories.GroupFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.groups.{FixedPlayersGroupStrategy, Group}
import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

let CONFIG_PLAYER_TYPES = map[[t: playerTypeId(): toLowerCase(), t: playerTypeId()] foreach t in getAllPlayerTypes()]

function createGroupFactory = {
	let factory = DynamicObject("PlayerControlThreadFactory"):
		define("createGroup", |this, cbProcessEvents| -> createConfiguredGroup(cbProcessEvents))

	return factory
}

local function createConfiguredGroup = |cbProcessEvents| {
	let config = getConfig()
	let createGroupTypes = [
			^_createConfiguredFixedPlayerGroup,
			^_createConfiguredLegacySinglePlayerGroup]
	foreach createGroupFunction in createGroupTypes {
		let group = createGroupFunction(cbProcessEvents, config)
		if (group != null) {
			return group
		}
	}
	raise("Error in configuration: could not create a player group")
}

local function _createConfiguredFixedPlayerGroup = |cbProcessEvents, config| {
	let playersConfig = config: get("players")
	if playersConfig is null {
		return null
	}
	
	let expectedPlayers = map[]
	
	foreach playerTypeConfig in playersConfig: entrySet() {
		let playerTypeId = _getConfiguredPlayerTypeId(playerTypeConfig: getKey())
		let playerTypeValues = playerTypeConfig: getValue()
		if (playerTypeValues: get("enabled") isnt null and playerTypeValues: get("enabled")) {
			let playerNames = [p foreach p in playerTypeValues: get("players")]
			let playerIds = list[createPlayerId(playerTypeId, p) foreach p in playerNames]
			expectedPlayers: put(playerTypeId,  playerIds)
		}
	}
	
	return _createFixedPlayerGroup(expectedPlayers, cbProcessEvents)
}


local function _createConfiguredLegacySinglePlayerGroup = |cbProcessEvents, config| {
	let playerConfig = config: get("player")
	if playerConfig is null {
		return null
	}
	
	let playerTypeInConfig = playerConfig: get("type")
	
	let playerTypeId = _getConfiguredPlayerTypeId(playerTypeInConfig)
	let playerName = playerConfig: get("name")
	let playerId = createPlayerId(playerTypeId, playerName)
	
	let expectedPlayers = map[[playerTypeId, list[playerId]]]
	return _createFixedPlayerGroup(expectedPlayers, cbProcessEvents)
}

local function _getConfiguredPlayerTypeId = |playerTypeInConfig| {
	let playerTypeId = CONFIG_PLAYER_TYPES: get(playerTypeInConfig)
	if (playerTypeId is null) {
		raise("Unknown player type specified in configuration: '" + playerTypeInConfig + "'")
	}
	return playerTypeId
}

local function _createFixedPlayerGroup = |expectedPlayers, cbProcessEvents| {
	let strategy = createFixedPlayersGroupStrategy(expectedPlayers, cbProcessEvents)
	let group = createGroup("Player Group", strategy)
	return group
}
