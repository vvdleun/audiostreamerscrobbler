module audiostreamerscrobbler.maintypes.Player

union PlayerTypes = {
	BluOs = { bluOsImpl }
	MusicCast = { musicCastImpl }
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
	let id = getPlayerTypeID(playerImpl: playerType()) + "/" + playerImpl: name()
	let player = DynamicObject("PlayerProxy"):
		define("impl", playerImpl):
		define("id", id):
		fallback(DynamicObject.delegate(playerImpl))

	return player
}