module audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl

import nl.vincentvanderleun.utils.ByteUtils
import audiostreamerscrobbler.utils.RequestUtils

import java.awt.Desktop
import java.io.{BufferedReader, InputStreamReader}
import java.lang.Thread
import java.net.URI
import java.security.MessageDigest
import java.util.{Calendar, Collections, stream.Collectors, TimeZone, TreeSet}

let DEFAULT_ENCODING = "UTF-8"

function createAudioScrobbler20Impl = |name, apiUrl, apiKey, apiSecret, sessionKey| {
	let scrobbler = DynamicObject("AudioScrobbler20Impl"):
		define("_apiUrl", apiUrl):
		define("_apiKey", apiKey):
		define("_apiSecret", apiSecret):
		define("_sessionKey", sessionKey):
		define("name", name):
		define("updateNowPlaying", |this, song| -> updateNowPlaying(this, song)):
		define("scrobble", |this, utcCalendar, song| -> scrobbleSong(this, utcCalendar, song))

	return scrobbler
}

function createAudioScrobbler20AuthorizeHelper = |configKey, apiUrl, authorizeUrl, apiKey, apiSecret| {
	let authorizeHelper = DynamicObject("AudioScrobbler20AuthorizeHelper"):
		define("_configKey", configKey):
		define("_apiUrl", apiUrl):
		define("_authorizeUrl", authorizeUrl):
		define("_apiKey", apiKey):
		define("_apiSecret", apiSecret):
		define("authorize", |this| -> authorizeAccountAndGetSessionKey(this))
	return authorizeHelper
}

# Authorize Helper

local function authorizeAccountAndGetSessionKey = |authHelper| {
	let configKey = authHelper: _configKey()
	let apiUrl = authHelper: _apiUrl()
	let apiKey = authHelper: _apiKey()
	let apiSecret = authHelper: _apiSecret()

	if (not Desktop.isDesktopSupported()) {
		println("A desktop GUI Internet browser is required to finish this procedure.")
		println("You can run this procedure on any machine, just copy and paste the returned session key to the '" + configKey + "' entry in the config.json file.")
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

local function scrobbleSong = |scrobbler, utcCalendar, song| {
	let timestamp = _createTimestamp(utcCalendar)
	requestPostScrobble(scrobbler: _apiUrl(), song, timestamp, scrobbler: _apiKey(), scrobbler: _apiSecret(), scrobbler: _sessionKey())
}

local function _createTimestamp = |utcCalendar| {
	# AudioScrobbler 2.0 uses UTC timestamp in seconds
	return utcCalendar: getTimeInMillis() / 1000
}

# Higher-level HTTP requests functions

local function requestPostScrobble = |apiUrl, song, timestamp, apiKey, apiSecret, sessionKey| {
	doHttpPostRequestAndReturnJSON(
		apiUrl,
		|o| {
			let postParams = createParamsWithSignature(
					_addSong(map[
						["method", "track.scrobble"],
						["timestamp", timestamp],
						["api_key", apiKey],
						["sk", sessionKey],
						["format", "json"]], song), apiSecret)
			o: write(postParams: getBytes(DEFAULT_ENCODING))
		})
}

function requestPostUpdateNowPlaying = |apiUrl, song, apiKey, apiSecret, sessionKey| {
	doHttpPostRequestAndReturnJSON(
		apiUrl,
		|o| {
			let postParams = createParamsWithSignature(
					_addSong(map[
						["method", "track.updateNowPlaying"],
						["api_key", apiKey],
						["sk", sessionKey],
						["format", "json"]], song), apiSecret)
			o: write(postParams: getBytes(DEFAULT_ENCODING))
		})
}

local function _addSong = |postParams, song| {
	let paramsWithSong = map[[es: key(), es: value()] foreach es in postParams: entrySet()]

	paramsWithSong: put("track", song: name())
	paramsWithSong: put("artist", song: artist())
	paramsWithSong: put("duration", song: length())
	if (not song: album(): isEmpty()) {
		paramsWithSong: put("album", song: album())
	}

	return paramsWithSong
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