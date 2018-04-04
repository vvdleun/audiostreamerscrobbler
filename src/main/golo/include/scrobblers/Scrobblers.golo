module audiostreamerscrobbler.scrobbler.Scrobblers

function createScrobblers = |scrobblers| {
	let scrobblersInstance = DynamicObject("Scrobblers"):
		define("_scrobblers", scrobblers):
		define("updatePlayingNow", |this, song| {
			this: _scrobblers(): each(|scrobbler| {
				scrobbler: updateNowPlaying(song)
			})
		}):
		define("scrobble", |this, song| {
			this: _scrobblers(): each(|scrobbler| {
				scrobbler: scrobble(song)
			})
		})

	return scrobblersInstance
}