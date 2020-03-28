module audiostreamerscrobbler.players.bluos.BluOsPlayer

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

struct BluOsPlayerImpl = {
	name,
	port,
	model,
	version,
	macAddress,
	ipAddress,
	LSDPVersionSupposedly,
	host
}

function createBluOsPlayer = |bluOsImpl| {
	let playerImpl = DynamicObject("BluOsPlayerImpl"):
		define("bluOsImpl", bluOsImpl):
		define("name", bluOsImpl: name()):
		define("playerType", PlayerTypes.BluOs()):
		define("friendlyName", |this| -> this: name() + " (Standard: BluOS, model: " + bluOsImpl: model() + ", version " + bluOsImpl: version() + ", IP address: " + bluOsImpl: ipAddress() + ", MAC address: " + bluOsImpl: macAddress() + ")")

	return playerImpl		
}

