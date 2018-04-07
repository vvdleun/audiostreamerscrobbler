module audiostreamerscrobbler.scrobbler.Scrobblers

import java.util.{Calendar, TimeZone}

function createScrobblers = |scrobblers| {
	let scrobblersInstance = DynamicObject("Scrobblers"):
		define("_scrobblers", scrobblers):
		define("updatePlayingNow", |this, song| {
			this: _scrobblers(): each(|scrobbler| {
				try {
					scrobbler: updateNowPlaying(song)
				} catch(ex) {
					println("Could not update Playing Now for service '" + scrobbler: name() + "': " + ex)
				}
			})
		}):
		define("scrobble", |this, song| {
			this: _scrobblers(): each(|scrobbler| {
				let utcTimestamp = _createTimestamp(song: position())
				scrobbler: scrobble(utcTimestamp, song)
			})
		})
		
	return scrobblersInstance
}

local function _createTimestamp = |songPosition| {
	let utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
	
	utcCalendar: set(Calendar.SECOND(), (utcCalendar: get(Calendar.SECOND()) - songPosition))
	return utcCalendar
}
