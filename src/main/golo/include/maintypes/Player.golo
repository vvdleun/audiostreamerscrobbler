module audiostreamerscrobbler.maintypes.Player

union PlayerTypes = {
	BLUESOUND
}

local function getPlayerTypeID = |playerType| {
	case {
		when playerType: isBLUESOUND() {
			return "BLUESOUND"
		}
		otherwise {
			raise("Internal error: unknown player type '" + playerType + "'")
		}
	}
}

function createPlayer = |playerImpl| {
	let id = getPlayerTypeID(playerImpl: playerType()) + "/" + playerImpl: name()
	let player = DynamicObject("PlayerProxy"):
		define("impl", playerImpl):
		define("id", id):
		fallback(DynamicObject.delegate(playerImpl))

	return player
}