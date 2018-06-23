module audiostreamerscrobbler.maintypes.Player

union PlayerTypes = {
	BluOs
	MusicCast
}

augment PlayerTypes {
	function playerTypeId = |this| -> getPlayerTypeID(this)
}

local function getPlayerTypeID = |playerType| {
	case {
		when playerType: isBluOs() {
			return "BluOS"
		}
		when playerType: isMusicCast() {
			return "MusicCast"
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