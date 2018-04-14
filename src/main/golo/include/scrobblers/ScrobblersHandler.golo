module audiostreamerscrobbler.scrobbler.ScrobblersHandler

import audiostreamerscrobbler.maintypes.Scrobble
import audiostreamerscrobbler.utils.ThreadUtils

import java.util.{Calendar, TimeZone}

function createScrobblersHandler = |scrobblers, missedScrobblesHandler| {
	let scrobblersInstance = DynamicObject("Scrobblers"):
		define("_scrobblers", scrobblers):
		define("updatePlayingNow", |this, song| {
			runInNewThread({
				this: _scrobblers(): each(|scrobbler| {
					try {
						scrobbler: updateNowPlaying(song)
					} catch(ex) {
						println("Could not update Playing Now for service '" + scrobbler: id() + "': " + ex)
					}
				})
			})
		}):
		define("scrobble", |this, song| {
			runInNewThread({
				this: _scrobblers(): each(|scrobbler| {
					let utcTimestamp = _createTimestamp(song: position())
					let scrobble = Scrobble(utcTimestamp, song)
					try {
						scrobbler: scrobble(scrobble)
					} catch(ex) {
						case {
							when ex oftype java.net.SocketException.class or ex oftype java.net.SocketTimeoutException.class {
								println("Could not scrobble to service '" + scrobbler: id() + "': " + ex)
								missedScrobblesHandler: addMissedScrobble(scrobbler: id(), scrobble)
							}
							otherwise {
								println("IGNORE UNKNOWN ERROR WHILE SCROBBLING TO SERVICE " + scrobbler: id() + ": " + ex)
							}
						}
					}
				})
			})
		})
		
	return scrobblersInstance
}

local function _createTimestamp = |songPosition| {
	let utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
	
	utcCalendar: set(Calendar.SECOND(), (utcCalendar: get(Calendar.SECOND()) - songPosition))
	return utcCalendar
}