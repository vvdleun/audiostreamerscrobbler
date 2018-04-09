module audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl

import nl.vincentvanderleun.utils.ByteUtils
import audiostreamerscrobbler.utils.RequestUtils

import gololang.IO
import java.awt.Desktop
import java.io.{BufferedReader, InputStreamReader}
import java.lang.Thread
import java.net.URI
import java.security.MessageDigest
import java.util.{Calendar, Collections, stream.Collectors, TimeZone, TreeSet}

let DEFAULT_ENCODING = "UTF-8"

function createAudioScrobbler20Impl = |id, apiUrl, apiKey, apiSecret, sessionKey| {
	let scrobbler = DynamicObject("AudioScrobbler20Impl"):
		define("_apiUrl", apiUrl):
		define("_apiKey", apiKey):
		define("_apiSecret", apiSecret):
		define("_sessionKey", sessionKey):
		define("id", id):
		define("updateNowPlaying", |this, song| -> updateNowPlaying(this, song)):
		define("scrobble", |this, scrobble| -> scrobbleSong(this, scrobble)):
		define("scrobbleAll", |this, scrobbles| -> scrobbleAll(this, scrobbles))

	return scrobbler
}

function createAudioScrobbler20AuthorizeHelper = |id, apiUrl, authorizeUrl, apiKey, apiSecret| {
	let authorizeHelper = DynamicObject("AudioScrobbler20AuthorizeHelper"):
		define("_apiUrl", apiUrl):
		define("_authorizeUrl", authorizeUrl):
		define("_apiKey", apiKey):
		define("_apiSecret", apiSecret):
		define("id", id):
		define("authorize", |this| -> authorizeAccountAndGetSessionKey(this))
	return authorizeHelper
}

# Authorize Helper

local function authorizeAccountAndGetSessionKey = |authHelper| {
	let id = authHelper: id()
	let apiUrl = authHelper: _apiUrl()
	let apiKey = authHelper: _apiKey()
	let apiSecret = authHelper: _apiSecret()

	if (not Desktop.isDesktopSupported()) {
		println("A desktop GUI Internet browser is required to finish this procedure.")
		println("You can run this procedure on any machine, just copy and paste the returned session key to the '" + id + "' entry in the config.json file.")
		return
	}

	let authToken = requestGetAuthToken(apiUrl, apiKey, apiSecret)
	println("Retrieved token: " + authToken)
	println("Your default desktop GUI browser has been opened. Login and when prompted, authorize the application.")
	
	let authorizeUrl = createAuthorizeUrl(authHelper: _authorizeUrl(), apiKey, authToken)
	Desktop.getDesktop(): browse(URI(authorizeUrl))
	try {
		println("Press enter once you have authorized the client.")
		readln()
	} catch(ex) {
		println("It seems the input channel is not available to the application. The application will wait 3 minutes to give you the chance to login.")
		println("After 3 minutes, the program will try to retrieve to continue the authorization process")
		Thread.sleep(60_L * 3 * 1000)
	}

	let session = requestGetSessionKey(apiUrl, authToken, apiKey, apiSecret)

	let sessionKey = session: get("session"): get("key")
}

# Scrobbler object helpers

local function updateNowPlaying = |scrobbler, song| {	
	requestPostUpdateNowPlaying(scrobbler: _apiUrl(), song, scrobbler: _apiKey(), scrobbler: _apiSecret(), scrobbler: _sessionKey())
}

local function scrobbleSong = |scrobbler, scrobble| {
	let apiUrl = scrobbler: _apiUrl()
	let apiKey = scrobbler: _apiKey()
	let apiSecret = scrobbler: _apiSecret()
	let sessionKey = scrobbler: _sessionKey()

	requestPostScrobbles(apiUrl, [scrobble], apiKey, apiSecret, sessionKey)
}

local function scrobbleAll = |scrobbler, scrobbles| {
	let apiUrl = scrobbler: _apiUrl()
	let apiKey = scrobbler: _apiKey()
	let apiSecret = scrobbler: _apiSecret()
	let sessionKey = scrobbler: _sessionKey()

	requestPostScrobbles(apiUrl, scrobbles, apiKey, apiSecret, sessionKey)
}

# Higher-level HTTP requests functions

local function requestPostScrobbles = |apiUrl, scrobbles, apiKey, apiSecret, sessionKey| {
	doHttpPostRequestAndReturnJSON(
		apiUrl,
		|o| {
			let postParams = map[
				["method", "track.scrobble"],
				["api_key", apiKey],
				["sk", sessionKey],
				["format", "json"]]

			if (scrobbles: size() == 1) {
				let scrobble = scrobbles: get(0)
				_addScrobble(postParams, scrobble)
			} else {
				range(scrobbles): each(|idx| {
					let scrobble = scrobbles: get(idx)
					let arrayIndex = "[" + idx: toString() + "]"
					_addScrobble(postParams, scrobble, arrayIndex)
				})
			}
			
			let postParamsWithSignature = createParamsWithSignature(postParams, apiSecret)
			println(postParamsWithSignature)
			o: write(postParamsWithSignature: getBytes(DEFAULT_ENCODING))
		})
}

function requestPostUpdateNowPlaying = |apiUrl, song, apiKey, apiSecret, sessionKey| {
	doHttpPostRequestAndReturnJSON(
		apiUrl,
		|o| {
			let postParams = map[
				["method", "track.updateNowPlaying"],
				["api_key", apiKey],
				["sk", sessionKey],
				["format", "json"]]

			_addSong(postParams, song)
				
			let postParamsWithSignature = createParamsWithSignature(postParams, apiSecret)
			println(postParamsWithSignature)
			o: write(postParamsWithSignature: getBytes(DEFAULT_ENCODING))
		})
}

local function _addScrobble = |postParams, scrobble| {
	# Single scrobble, so no array index suffix
	_addScrobble(postParams, scrobble, "")
}

local function _addScrobble = |postParams, scrobble, suffix| {
	_addSong(postParams, scrobble: song(), suffix)
	postParams: put("timestamp" + suffix, _createTimestamp(scrobble: utcTimestamp()))
}

local function _addSong = |postParams, song| {
	# Single song, so no array index suffix
	_addSong(postParams, song, "")
}

local function _addSong = |postParams, song, suffix| {
	postParams: put("track" + suffix, song: name())
	postParams: put("artist" + suffix, song: artist())
	postParams: put("duration" + suffix, song: length())
	if (not song: album(): isEmpty()) {
		postParams: put("album" + suffix, song: album())
	}
}

local function _createTimestamp = |utcCalendar| {
	# AudioScrobbler 2.0 uses UTC timestamp in seconds
	return utcCalendar: getTimeInMillis() / 1000
}

local function requestGetSessionKey = |apiUrl, authToken, apiKey, apiSecret| {
	let url = createGetSessionKeyUrl(apiUrl, authToken, apiKey, apiSecret)
	return doHttpGetRequestAndReturnJSON(url)
}

local function requestGetAuthToken = |apiUrl, apiKey, apiSecret|	{
	let url = createGetAuthTokenUrl(apiUrl, apiKey, apiSecret)
	return doHttpGetRequestAndReturnJSON(url): get("token")
}


# High-level URL creation functions

local function createGetSessionKeyUrl = |apiUrl, authToken, apiKey, apiSecret| {
	let sessionValues = map[["method", "auth.getSession"], ["token", authToken], ["api_key", apiKey], ["format", "json"]]
	return apiUrl + "?" + createParamsWithSignature(sessionValues, apiSecret)
}

local function createAuthorizeUrl = |authorizeUrl, apiKey, authToken| {
	let authValues = map[["api_key", apiKey], ["token", authToken]]
	return authorizeUrl + "?" + createParams(authValues)
}

local function createGetAuthTokenUrl = |apiUrl, apiKey, apiSecret| {
	let apiValues = map[["method", "auth.gettoken"], ["api_key", apiKey], ["format", "json"]]
	return apiUrl + "?" + createParamsWithSignature(apiValues, apiSecret)
}

# URL helper functions

local function createParamsWithSignature = |params, apiSecret| {
	let apiSig = createApiSignature(params, apiSecret)

	let paramsWithSecret = map[[es: key(), es: value()] foreach es in params: entrySet()]
	paramsWithSecret: put("api_sig", apiSig)

	return createParams(paramsWithSecret)
}

local function createParams = |params| {
	return [es: key() + "=" + es: value() foreach es in params: entrySet()]: join("&")
}

local function createApiSignature = |params, secret| {
	let apiSignature = StringBuilder()
	let orderedKeys = list[es: key() foreach es in params: entrySet() when es: key() != "format"]: order()
	apiSignature: append([e + params: get(e): toString() foreach e in orderedKeys]: join(""))
	apiSignature: append(secret)
	
	let md5HashBytes = MessageDigest.getInstance("MD5"): digest(apiSignature: toString(): getBytes("UTF-8"))	
	
	let md5StringArray = [
		Integer.toString(toUnsignedByte(md5HashBytes: get(i)) + 256, 16): substring(1) foreach i in range(md5HashBytes: length())
	]
	
	return md5StringArray: join("")
}