module audiostreamerscrobbler.maintypes.Player

let PLAYERTYPE_ID_BLUOS = "BluOS"
let PLAYERTYPE_ID_HEOS = "HEOS"
let PLAYERTYPE_ID_MUSICCAST = "MusicCast"

union PlayerTypes = {
	BluOs
	Heos
	MusicCast
}

augment PlayerTypes {
 	function playerTypeId = |this| -> getPlayerTypeID(this)
}

function getAllPlayerTypes = {
	return [PlayerTypes.BluOs(), PlayerTypes.Heos(), PlayerTypes.MusicCast()]
}

function createPlayer = |playerImpl| {
	let playerTypeId = getPlayerTypeID(playerImpl: playerType())
	let playerId = createPlayerId(playerTypeId, playerImpl: name())
	let player = DynamicObject("PlayerProxy"):
		define("impl", playerImpl):
		define("id", playerId):
		define("playerTypeId", getPlayerTypeID(playerImpl: playerType())):
		fallback(DynamicObject.delegate(playerImpl))

	return player
}

function createPlayerId = |playerTypeId, playerName| {
	return playerTypeId + "/" + playerName
}

function getPlayerType = |playerTypeId| {
	case {
		when playerTypeId == PLAYERTYPE_ID_BLUOS {
			return PlayerTypes.BluOs()
		}
		when playerTypeId == PLAYERTYPE_ID_HEOS {
			return PlayerTypes.Heos()
		}
		when playerTypeId == PLAYERTYPE_ID_MUSICCAST {
			return PlayerTypes.MusicCast()
		}
		otherwise {
			raise("Internal error: unknown player type ID '" + playerTypeId + "'")
		}
	}
}

function getPlayerTypeID = |playerType| {
	case {
		when playerType: isBluOs() {
			return PLAYERTYPE_ID_BLUOS
		}
		when playerType: isHeos() {
			return PLAYERTYPE_ID_HEOS
		}
		when playerType: isMusicCast() {
			return PLAYERTYPE_ID_MUSICCAST
		}
		otherwise {
			raise("Internal error: unknown player type '" + playerType + "'")
		}
	}
}
