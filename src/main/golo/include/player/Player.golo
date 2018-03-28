module audiostreamerscrobbler.player.Player

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
		define("_impl", playerImpl):
		define("id", id):
		fallback(DynamicObject.delegate(playerImpl))

	# Lock because the usage playerImpl instead of this: _impl() in the fallback
	player: freeze()
	
	return player
}