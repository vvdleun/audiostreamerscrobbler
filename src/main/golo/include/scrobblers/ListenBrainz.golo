module audiostreamerscrobbler.scrobbler.ListenBrainz

import nl.vincentvanderleun.scrobbler.exceptions.ScrobblerException
import nl.vincentvanderleun.utils.ByteUtils

import gololang.IO
import gololang.JSON
import java.lang.Thread

let TRACKER_ID = "listenbrainz"
let DEFAULT_ENCODING = "UTF-8"
let MAX_SONGS = 100
let MAX_LISTEN_SIZE = 10240
let MAX_DAYS = 30

let API_URL = "https://api.listenbrainz.org/1/submit-listens"

let HTTP_HEADER_AUTHORIZE = "Authorization"

let LISTEN_TYPE_PLAYING_NOW = "playing_now"
let LISTEN_TYPE_SINGLE = "single"
let LISTEN_TYPE_IMPORT = "import"

function getListenBrainzId = -> TRACKER_ID

function createListenBrainzTracker = |httpRequestFactory, userToken| {
	httpRequestFactory: customProperties(map[[HTTP_HEADER_AUTHORIZE, "Token " + userToken]])
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

function createListenBrainzAuthorizor = {
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

local function jsonBytes = |x| -> JSON.stringify(x): getBytes(DEFAULT_ENCODING): size()

local function updateNowPlaying = |tracker, song| {
	let payload = [createPayloadItemFromSong(song)]
	validatePayloadSize(payload)
	sendSubmissions(tracker, LISTEN_TYPE_PLAYING_NOW, payload)
}

local function scrobbleSong = |tracker, scrobble| {
	let payload = [createPayloadItemFromScrobble(scrobble)]
	validatePayloadSize(payload)
	sendSubmissions(tracker, LISTEN_TYPE_SINGLE, payload)
}

local function scrobbleAll = |tracker, scrobbles| {
	let payload = [createPayloadItemFromScrobble(s) foreach s in scrobbles]
	sendSubmissions(tracker, LISTEN_TYPE_IMPORT, payload)
}

# Helper functions

local function validatePayloadSize = |payload| {
	let payloadSize = jsonBytes(payload)
	if (payloadSize > MAX_LISTEN_SIZE) {
		raise(ScrobblerException("Payload size of " + payloadSize: toString() + " bytes would exceed ListenBrainz' maximal size of " + MAX_LISTEN_SIZE: toString() + " bytes", false))
	}
}

local function sendSubmissions = |tracker, listen_type, payload| {
	let httpRequest = tracker: _httpRequest()
	let chunks = divideListInChunks(payload, MAX_SONGS, MAX_LISTEN_SIZE)
	foreach chunk in chunks {
		requestPostSubmissions(httpRequest, listen_type, chunk)
		# To do: use ListenBrainz' HTTP headers to find out whether 
		Thread.sleep(5000_L)
	}
}

function divideListInChunks = |payload, chunkMaxItems, chunkMaxSize| {
	let fullList = list[pi foreach pi in payload]
	# TODO refactor this @#$$^%^ $^*$@$#%^
	if (fullList: size() == 0 or chunkMaxItems <= 0) {
		return list[]
	}

	let chunks = list[list[]]
	while (fullList: size() > 0) {
		let lastChunk = chunks: last()
		# TODO This is most absolutely definitely NOT efficient...
		if (lastChunk: size() >= chunkMaxItems or jsonBytes(lastChunk) + jsonBytes(fullList: head()) > MAX_LISTEN_SIZE) {
			chunks: add(list[])
			continue
		}
		
		let item = fullList: pop()
		lastChunk: add(item)
	}
	return chunks
} 

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

local function createPayloadItemFromSong = |song| {
	return _createPayloadItem(song, null)
}
	
local function createPayloadItemFromScrobble = |scrobble| {
	return _createPayloadItem(scrobble: song(), scrobble: utcTimestamp())
}

local function _createPayloadItem = |song, timestamp| {
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