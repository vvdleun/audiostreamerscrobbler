module audiostreamerscrobbler.maintypes.Player

let PLAYERTYPE_ID_BLUOS = "BluOS"
let PLAYERTYPE_ID_MUSICCAST = "MusicCast"

union PlayerTypes = {
	BluOs
	MusicCast
}

augment PlayerTypes {
	function playerTypeId = |this| -> getPlayerTypeID(this)
}

function getPlayerType = |playerTypeId| {
	case {
		when playerTypeId == PLAYERTYPE_ID_BLUOS {
			return PlayerTypes.BluOs()
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
		when playerType: isMusicCast() {
			return PLAYERTYPE_ID_MUSICCAST
		}
		otherwise {
			raise("Internal error: unknown player type '" + playerType + "'")
		}
	}
}

function createPlayer = |playerImpl| {
	let playerTypeId = getPlayerTypeID(playerImpl: playerType())
	let id = playerTypeId + "/" + playerImpl: name()
	let player = DynamicObject("PlayerProxy"):
		define("impl", playerImpl):
		define("id", id):
		define("playerTypeId", getPlayerTypeID(playerImpl: playerType())):
		fallback(DynamicObject.delegate(playerImpl))

	return player
}