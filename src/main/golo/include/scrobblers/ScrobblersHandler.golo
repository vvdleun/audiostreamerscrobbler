module audiostreamerscrobbler.scrobbler.ScrobblersHandler

import audiostreamerscrobbler.maintypes.ScrobbleType.types.Scrobble
import audiostreamerscrobbler.utils.ThreadUtils

import java.util.{Calendar, TimeZone}

function createScrobblersHandler = |scrobblers, missedScrobblesHandler| {
	let scrobblersInstance = DynamicObject("Scrobblers"):
		define("_scrobblers", scrobblers):
		define("updatePlayingNow", |this, song| {
			runInNewThread("UpdatePlayingNowThread", {
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
			runInNewThread("ScrobbleSongThread", {
				this: _scrobblers(): each(|scrobbler| {
					let utcTimestamp = _createTimestamp(song: position())
					let scrobble = Scrobble(utcTimestamp, song)
					try {
						scrobbler: scrobble(scrobble)
					} catch(ex) {
						if (shouldRetryScrobble(ex)) {
							println("Could not scrobble to service '" + scrobbler: id() + "' will try later. Reason: " + ex)
							missedScrobblesHandler: addMissedScrobble(scrobbler: id(), scrobble)
						} else {
							println("Unknown error occured, Scrobble will be lost for:  " + scrobbler: id() + ". Reason: " + ex)
						}
					}
				})
			})
		})
		
	return scrobblersInstance
}

local function shouldRetryScrobble = |ex| {
	case {
		# TODO: just always retry IOExceptions exceptions?
		when ex oftype nl.vincentvanderleun.scrobbler.exceptions.ScrobblerException.class {
			return ex: shouldRetryLater()
		}
		when ex oftype java.io.IOException.class {
			return true
		}
		otherwise {
			return false
		}
	}
}

local function _createTimestamp = |songPosition| {
	let utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
	
	utcCalendar: set(Calendar.SECOND(), (utcCalendar: get(Calendar.SECOND()) - songPosition))
	return utcCalendar
}