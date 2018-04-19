module audiostreamerscrobbler.scrobbler.ListenBrainz

import nl.vincentvanderleun.scrobbler.exceptions.ScrobblerException
import nl.vincentvanderleun.utils.ByteUtils

import gololang.IO
import gololang.JSON

let TRACKER_ID = "listenbrainz"
let DEFAULT_ENCODING = "UTF-8"
let MAX_SCROBBLES = 50
let MAX_DAYS = 30

let API_URL = "https://api.listenbrainz.org/1/submit-listens"

let LISTEN_TYPE_PLAYING_NOW = "playing_now"
let LISTEN_TYPE_SINGLE = "single"
let LISTEN_TYPE_IMPORT = "import"

function getListenBrainzId = {
	return TRACKER_ID
}

function createListenBrainzTracker = |httpRequestFactory, userToken| {
	httpRequestFactory: customProperties(map[["Authorization", "Token " + userToken]])
	let httpRequest = httpRequestFactory: createHttpRequest()
	
	let scrobbler = DynamicObject("ListenBrainzListenTracker"):
		define("_userToken", userToken):
		define("_httpRequest", httpRequest):
		define("id", TRACKER_ID):
		define("maximalDaysOld", MAX_DAYS):
		define("updateNowPlaying", |this, song| -> updateNowPlaying(this, song)):
		define("scrobble", |this, scrobble| -> scrobbleSong(this, scrobble)):
		define("scrobbleAll", |this, scrobbles| -> scrobbleAll(this, scrobbles))

	return scrobbler
}

function createLIstenBrainzAuthorizor = {
	let authorizeHelper = DynamicObject("ListenBrainzAuthorizeHelper"):
		define("id", TRACKER_ID):
		define("authorize", |this| -> showAuthorizeHelp())

	return authorizeHelper
}

# Authorize Helper

local function showAuthorizeHelp = {
	println("\n\nVisit https://listenbrainz.org and log in to find your user token. Paste this in the '" + TRACKER_ID + "' entry in your config.json file.\n")
}

# Tracker helpers

local function updateNowPlaying = |tracker, song| {
	let httpRequest = tracker: _httpRequest()
	let payload = [createPayloadFromSong(song)]
	requestPostSubmissions(httpRequest, LISTEN_TYPE_PLAYING_NOW, payload)
}

local function scrobbleSong = |tracker, scrobble| {
	let httpRequest = tracker: _httpRequest()
	let payload = [createPayloadFromScrobble(scrobble)]
	requestPostSubmissions(httpRequest, LISTEN_TYPE_SINGLE, payload)
}

local function scrobbleAll = |tracker, scrobbles| {
	let httpRequest = tracker: _httpRequest()
	let payload = [createPayloadFromScrobble(s) foreach s in scrobbles]
	requestPostSubmissions(httpRequest, LISTEN_TYPE_IMPORT, [s: song() foreach s in scrobbles])
}

# Higher-level HTTP requests functions

local function requestPostSubmissions = |httpRequest, listenType, payload| {
	httpRequest: doHttpPostRequestAndReturnJSON(
		API_URL,
		"application/json",
		|o| {
			let postValues = map[
				["listen_type", listenType],
				["payload", payload]]

			let postValuesJson = JSON.stringify(postValues)
			o: write(postValuesJson: getBytes(DEFAULT_ENCODING))
		})
}

local function createPayloadFromSong = |song| {
	return _createPayload(song, null)
}
	
local function createPayloadFromScrobble = |scrobble| {
	return _createPayload(scrobble: song(), scrobble: utcTimestamp())
}

local function _createPayload = |song, timestamp| {
	let payload = map[
		["track_metadata", map[
			["artist_name", song: artist()],
			["track_name", song: name()],
			["release_name", song: album()]]]]

	if (timestamp isnt null) {
		payload: put("listened_at", _createTimestamp(timestamp))
	}

	return payload
}

local function _createTimestamp = |utcCalendar| {
	return utcCalendar: getTimeInMillis() / 1000
}