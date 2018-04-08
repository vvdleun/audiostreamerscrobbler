module audiostreamerscrobbler.scrobbler.ScrobblersHandler

import audiostreamerscrobbler.maintypes.Scrobble

import java.util.{Calendar, TimeZone}

function createScrobblersHandler = |scrobblers, missedScrobblesHandler| {
	let scrobblersInstance = DynamicObject("Scrobblers"):
		define("_scrobblers", scrobblers):
		define("updatePlayingNow", |this, song| {
			this: _scrobblers(): each(|scrobbler| {
				try {
					scrobbler: updateNowPlaying(song)
				} catch(ex) {
					println("Could not update Playing Now for service '" + scrobbler: id() + "': " + ex)
				}
			})
		}):
		define("scrobble", |this, song| {
			this: _scrobblers(): each(|scrobbler| {
				let utcTimestamp = _createTimestamp(song: position())
				let scrobbledSong = Scrobble(utcTimestamp, song)
				try {
					scrobbler: scrobble(scrobbledSong)
				} catch(ex) {
					# TODO use the missedScrobblesHandler...
					throw(ex)
				}
			})
		})
		
	return scrobblersInstance
}

local function _createTimestamp = |songPosition| {
	let utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
	
	utcCalendar: set(Calendar.SECOND(), (utcCalendar: get(Calendar.SECOND()) - songPosition))
	return utcCalendar
}
