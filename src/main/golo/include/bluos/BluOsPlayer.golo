module audiostreamerscrobbler.bluos.BluOsPlayer

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

function createBluOsPlayerImpl = |bluOsImpl| {
	let playerImpl = DynamicObject("BluOsPlayerImpl"):
		define("name", bluOsImpl: name()):
		define("playerType", PlayerTypes.BluOs(bluOsImpl)):
		define("friendlyName", |this| -> this: name() + " (Standard: BluOS, model: " + bluOsImpl: model() + ", version " + bluOsImpl: version() + ", IP address: " + bluOsImpl: ipAddress() + ", MAC address: " + bluOsImpl: macAddress() + ")")

	return playerImpl		
}

