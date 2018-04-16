module audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl

import audiostreamerscrobbler.maintypes.AudioStreamerScrobblerHttpRequest

import nl.vincentvanderleun.scrobbler.exceptions.ScrobblerException
import nl.vincentvanderleun.utils.ByteUtils

import gololang.IO
import java.awt.Desktop
import java.io.{BufferedReader, InputStreamReader}
import java.lang.Thread
import java.net.{URI, URLEncoder}
import java.security.MessageDigest
import java.util.{Calendar, Collections, stream.Collectors, TimeZone, TreeSet}

let DEFAULT_ENCODING = "UTF-8"
let MAX_SCROBBLES = 50
let ERROR_CODES_RETRY = list["8", "11", "16", "29"]

function createAudioScrobbler20Impl = |id, apiUrl, apiKey, apiSecret, sessionKey, maximalDaysOld| {
	let scrobbler = DynamicObject("AudioScrobbler20Impl"):
		define("_apiUrl", apiUrl):
		define("_apiKey", apiKey):
		define("_apiSecret", apiSecret):
		define("_sessionKey", sessionKey):
		define("_httpRequest", createHttpRequest()):
		define("id", id):
		define("maximalDaysOld", maximalDaysOld):
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
		define("_httpRequest", createHttpRequest()):
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
	let httpRequest = authHelper: _httpRequest()

	if (not Desktop.isDesktopSupported()) {
		println("A desktop GUI Internet browser is required to finish this procedure.")
		println("You can run this procedure on any machine, just copy and paste the returned session key to the '" + id + "' entry in the config.json file.")
		return
	}

	let authToken = requestGetAuthToken(httpRequest, apiUrl, apiKey, apiSecret)
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

	let session = requestGetSessionKey(httpRequest, apiUrl, authToken, apiKey, apiSecret)

	let sessionKey = session: get("session"): get("key")

	println("Copy and paste the following Session Key to the 'sessionKey' field of the '" + id + "' entry in your config.json file:")
	println(sessionKey)
}

# Scrobbler object helpers

local function updateNowPlaying = |scrobbler, song| {	
	let apiUrl = scrobbler: _apiUrl()
	let apiKey = scrobbler: _apiKey()
	let apiSecret = scrobbler: _apiSecret()
	let sessionKey = scrobbler: _sessionKey()
	let httpRequest = scrobbler: _httpRequest()

	requestPostUpdateNowPlaying(httpRequest, apiUrl, song, apiKey, apiSecret, sessionKey)
}

local function scrobbleSong = |scrobbler, scrobble| {
	scrobbleAll(scrobbler, [scrobble])
}

local function scrobbleAll = |scrobbler, scrobbles| {
	let apiUrl = scrobbler: _apiUrl()
	let apiKey = scrobbler: _apiKey()
	let apiSecret = scrobbler: _apiSecret()
	let sessionKey = scrobbler: _sessionKey()
	let httpRequest = scrobbler: _httpRequest()

	var result = null
	try {
		result = requestPostScrobbles(httpRequest, apiUrl, scrobbles, apiKey, apiSecret, sessionKey)
	} catch(ex) {
		# ScrobblerHandler should take care of network errors
		case {
			when ex oftype nl.vincentvanderleun.utils.exceptions.HttpRequestException.class {
				throw(ScrobblerException(ex, true))
			}
			otherwise {
				throw(ex)
			}
		}
	}

	if (result isnt null) {
		if result: containsKey("error") {
			let errorCode = result: get("error"): toString()
			let retryLater = ERROR_CODES_RETRY: contains(errorCode)
			let msg = result: getOrElse("message", "null")
			throw(ScrobblerException("Reported AudioScrobbler 2.0 API error code: '" + errorCode + "', message='" + msg + "'", retryLater))
		}
	}
}

# Higher-level HTTP requests functions

local function requestPostScrobbles = |httpRequest, apiUrl, scrobbles, apiKey, apiSecret, sessionKey| {
	return httpRequest: doHttpPostRequestAndReturnJSON(
		apiUrl,
		|o| {
			divideListInChunks(list[s foreach s in scrobbles], MAX_SCROBBLES): each(|chunk| {
				let postParams = map[
					["method", "track.scrobble"],
					["api_key", apiKey],
					["sk", sessionKey],
					["format", "json"]]

				# Add scrobbles to postParams
				range(chunk: size()): each(|idx| {
					if (chunk: size() == 1) {
						# Just one song, do not add array notation
						_addScrobble(postParams, chunk: get(0))
					} else {
						# Multiple songs, add array index "[<index>]" to each scrobble
						let scrobble = chunk: get(idx)
						let arrayIndex = "[" + idx: toString() + "]"
						_addScrobble(postParams, scrobble, arrayIndex)
					}
				})

				let postParamsWithSignature = createParamsWithSignature(postParams, apiSecret)
				o: write(postParamsWithSignature: getBytes(DEFAULT_ENCODING))
			})
		})
}

function requestPostUpdateNowPlaying = |httpRequest, apiUrl, song, apiKey, apiSecret, sessionKey| {
	httpRequest: doHttpPostRequestAndReturnJSON(
		apiUrl,
		|o| {
			let postParams = map[
				["method", "track.updateNowPlaying"],
				["api_key", apiKey],
				["sk", sessionKey],
				["format", "json"]]

			_addSong(postParams, song)

			let postParamsWithSignature = createParamsWithSignature(postParams, apiSecret)
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

local function requestGetSessionKey = |httpRequest, apiUrl, authToken, apiKey, apiSecret| {
	let url = createGetSessionKeyUrl(apiUrl, authToken, apiKey, apiSecret)
	return httpRequest: doHttpGetRequestAndReturnJSON(url)
}

local function requestGetAuthToken = |httpRequest, apiUrl, apiKey, apiSecret|	{
	let url = createGetAuthTokenUrl(apiUrl, apiKey, apiSecret)
	return httpRequest: doHttpGetRequestAndReturnJSON(url): get("token")
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
	let urlEncode = |v| -> URLEncoder.encode(v: toString(), DEFAULT_ENCODING)

	return [es: key() + "=" + urlEncode(es: value()) foreach es in params: entrySet()]: join("&")
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

local function divideListInChunks = |fullList, chunkSize| {
	# TODO refactor this @#$$^%^
	if (fullList: size() == 0 or chunkSize <= 0) {
		return list[]
	}

	let chunks = list[list[]]
	while (fullList: size() > 0) {
		let lastChunk = chunks: get(chunks: size() - 1)
		if (lastChunk: size() >= chunkSize) {
			chunks: add(list[])
			continue
		}
		
		let item = fullList: pop()
		lastChunk: add(item)
	}
	return chunks
}