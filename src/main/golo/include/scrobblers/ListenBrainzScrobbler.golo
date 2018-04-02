module audiostreamerscrobbler.scrobbler.ListenBrainzScrobbler

import nl.vincentvanderleun.utils.ByteUtils
import audiostreamerscrobbler.utils.RequestUtils

let API_URL = "https://api.listenbrainz.org"
let API_PATH_LISTENS = "/1/submit-listens"

let DEFAULT_ENCODING = "UTF-8"

function createListenBrainzScrobbler = |userToken| {
	let scrobbler = DynamicObject("AudioScrobbler20Impl"):
		define("_userToken", userToken):
		define("updateNowPlaying", |this, song| -> updateNowPlaying(this, song)):
		define("scrobble", |this, song| -> scrobbleSong(this, song))

	return scrobbler
}

function createListenBrainzScrobblerAuthorizeHelper = |configKey| {
	let authorizeHelper = DynamicObject("ListenBrainzAuthorizeHelper"):
		define("_configKey", configKey):
		define("authorize", |this| -> authorizeAccountInfo(this))
	return authorizeHelper
}

# Authorize Helper

local function authorizeAccountInfo = |authHelper| {
	let configKey = authHelper: _configKey()
	println("Visit the https://listenbrainz.org website, login and find your User token in your account info.")
	println("Copy and paste that token in the '" + configKey + "' entry in the config.json file")
}

# Scrobbler object helpers

local function updateNowPlaying = |scrobbler, song, userToken| {	
	requestPostUpdateNowPlaying(API_URL, song, scrobbler: userToken())
}

local function scrobbleSong = |scrobbler, song| {
	# let timestamp = _createTimestamp(song)
	# requestPostScrobble(scrobbler: _apiUrl(), song, timestamp, scrobbler: _apiKey(), scrobbler: _apiSecret(), scrobbler: _sessionKey())
}

local function _createTimestamp = |song| {
	let utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
	let seconds = utcCalendar: getTimeInMillis() / 1000
	return seconds - song: position()
}

# Higher-level HTTP requests functions

local function requestPostScrobble = |apiUrl, song, timestamp, userToken| {

}

function requestPostUpdateNowPlaying = |apiUrl, song, userToken| {
	doHttpPostRequestAndReturnJSON(
		createListenAPIURL(),
		DEFAULT_ENCODING,
		10,
		|o| {
			let songMap = _createSongMap(song)
			let jsonString = json.stringify(map[
				["listen_type", "playing_now"],
				["payload", [
					_createSongMap(song)
				]]
			])
			o: write(jsonString: getBytes(DEFAULT_ENCODING))
		},
		-> map[["Authorization", userToken]])
}

local function _createSongMap = |song| {
	let trackMetadata = map[["track_name", song: name()], ["artist_name", song: artist()]]
	if (not song: album(): isEmpty()) {
		trackMetadata: put("release_name", song: album())
	}

	let songMap = map[["track_metadata", trackMetadata]]

	return songMap
}


# High-level URL creation functions

local function createListenAPIURL = {
	return API_URL + API_PATH_LISTENS
}
