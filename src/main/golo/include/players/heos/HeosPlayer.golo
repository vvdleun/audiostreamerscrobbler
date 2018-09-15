module audiostreamerscrobbler.players.heos.HeosPlayer

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

struct HeosImpl = {
	pid,
	name,
	model,
	ip
}

function createHeosPlayer = |heosImpl| {
	let playerImpl = DynamicObject("HeosPlayerImpl"):
		define("heosImpl", heosImpl):
		define("name", heosImpl: name()):
		define("playerType", PlayerTypes.Heos()):
		define("friendlyName", |this| -> this: name() + " (Standard: HEOS, model: " + heosImpl: model() + ", IP: " + heosImpl: ip() + ", id: " + heosImpl: pid() + ")")

	return playerImpl		
}

