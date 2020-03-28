module audiostreamerscrobbler.players.musiccast.MusicCastPlayer

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes

struct MusicCastImpl = {
	name,
	model,
	manufacturer,
	host,
	urlBase,
	yxcControlUrl
}

function createMusicCastPlayer = |musicCastImpl| {
	let playerImpl = DynamicObject("MusicCastPlayerImpl"):
		define("musicCastImpl", musicCastImpl):
		define("name", musicCastImpl: name()):
		define("playerType", PlayerTypes.MusicCast()):
		define("friendlyName", |this| -> this: name() + " (Standard: MusicCast, model: " + musicCastImpl: model() + ", manufacturer: " + musicCastImpl: manufacturer() + ", host: " + musicCastImpl: host() + ")")

	return playerImpl		
}

