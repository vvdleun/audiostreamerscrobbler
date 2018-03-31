module audiostreamerscrobbler.scrobbler.GnuFmScrobbler

import nl.vincentvanderleun.utils.ByteUtils
import audiostreamerscrobbler.utils.RequestUtils

import java.awt.Desktop
import java.io.{BufferedReader, InputStreamReader, IOException}
import java.lang.Thread
import java.net.URI
import java.security.MessageDigest
import java.util.Collections
import java.util.stream.Collectors
import java.util.TreeSet

let API_URL_PATH = "2.0/"

function createGnuFmScrobbler = |nixtapeUrl, apiKey, apiSecret, sessionKey| {
	let scrobbler = DynamicObject("GnuFMScrobbler"):
		define("_url", nixtapeUrl):
		define("_apiKey", apiKey):
		define("_apiSecret", apiSecret):
		define("_sessionKey", sessionKey):
		define("updateNowPlaying", |this, song| -> updateNowPlaying(this: _url(), song, this: apiKey(), this: apiSecret(), this: sessionKey()))
}

function authorizeAccountAndGetSessionKey = |nixtapeUrl, apiKey, apiSecret| {
	let authToken = requestGetAuthToken(nixtapeUrl, apiKey, apiSecret)
	let authorizeUrl = createAuthorizeUrl(nixtapeUrl, apiKey, authToken)

	if (not Desktop.isDesktopSupported()) {
		println("The program cannot start your default browser on a GUI desktop. Please visit the following URL manually on a system with an Internet browser")
		println(authorizeUrl)
		return
	}

	Desktop.getDesktop(): browse(URI(authorizeUrl))
	try {
		println("Press enter once you have authorized the client.")
		readln()
	} catch(ex) {
		println("It seems the input channel is not available to the application. The application will wait 2 minutes to give you the chance to login.")
		println("After 2 minutes, the program will try to retrieve to continue the authorization process")
		Thread.sleep(60_L * 2 * 1000)
	}
	let session = requestGetSessionKey(nixtapeUrl, authToken, apiKey, apiSecret)
	return session: get("session"): get("key")
}

# Scrobbler object helpers

function updateNowPlaying = |nixtapeUrl, song, apiKey, apiSecret, sessionKey| {
	requestPostUpdateNowPlaying(nixtapeUrl, apiKey, apiSecret)
}


# High-level HTTP requests functions

function requestPostUpdateNowPlaying = |nixtapeUrl, song, apiKey, apiSecret, sessionKey| {
	let url = createUpdateNowPlayingParams(nixtapeUrl)
	let output = doHttpPostRequest(
		url,
		10,
		|o| {
			let postParams = createParamsWithSignature(
					_addSong(map[
						["method", "track.updateNowPlaying"],
						["api_key", apiKey],
						["sk", sessionKey],
						["format", "json"]], song), apiSecret)
			o: write(postParams: getBytes("UTF-8"))
		},
		|i| { 
			let reader = BufferedReader(InputStreamReader(i, "UTF-8"))
			return JSON.parse(reader: lines(): collect(Collectors.joining("\n")))
		})
	println(output)
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

local function requestGetSessionKey = |nixtapeUrl, authToken, apiKey, apiSecret| {
	let url = createGetSessionKeyUrl(nixtapeUrl, authToken, apiKey, apiSecret)
	return doHttpGetRequestAndReturnJSON(url)
}

local function requestGetAuthToken = |nixtapeUrl, apiKey, apiSecret|	{
	let url = createGetAuthTokenUrl(nixtapeUrl, apiKey, apiSecret)
	return doHttpGetRequestAndReturnJSON(url): get("token")
}


# High-level URL creation functions

local function createUpdateNowPlayingParams = |nixTapeUrl| {
	return createApiPostUrl(nixTapeUrl)
}

local function createGetSessionKeyUrl = |nixtapeUrl, authToken, apiKey, apiSecret| {
	let sessionValues = map[["method", "auth.getSession"], ["token", authToken], ["api_key", apiKey], ["format", "json"]]
	return createApiUrl(nixtapeUrl) + createParamsWithSignature(sessionValues, apiSecret)
}

local function createAuthorizeUrl = |nixtapeUrl, apiKey, authToken| {
	let authValues = map[["api_key", apiKey], ["token", authToken]]
	return createFormattedUrl(nixtapeUrl, "/api/auth") + createParams(authValues)
}


local function createGetAuthTokenUrl = |nixtapeUrl, apiKey, apiSecret| {
	let apiValues = map[["method", "auth.gettoken"], ["api_key", apiKey], ["format", "json"]]
	return createApiUrl(nixtapeUrl) + createParamsWithSignature(apiValues, apiSecret)
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
	let orderedKeys = list[es: key() foreach es in params: entrySet()]: order()
	apiSignature: append([e + params: get(e): toString() foreach e in orderedKeys]: join(""))
	apiSignature: append(secret)
	
	let md5HashBytes = MessageDigest.getInstance("MD5"): digest(apiSignature: toString(): getBytes("UTF-8"))	
	
	let md5StringArray = [
		Integer.toString(toUnsignedByte(md5HashBytes: get(i)) + 256, 16): substring(1) foreach i in range(md5HashBytes: length())
	]

	return md5StringArray: join("")
}

# Low-level URL creation functions

local function createApiPostUrl = |url| {
	let url2 = createFormattedUrl(url, API_URL_PATH)
	return url2: substring(0, url2: length() - 1)
}

local function createApiUrl = |url| {
	return createFormattedUrl(url, API_URL_PATH)
}

local function createFormattedUrl = |url, path| {
	let formattedUrl = StringBuilder()

	let startUrl = createFormattedUrl(url)
	formattedUrl: append(startUrl: substring(0, startUrl: length() - 1))

	if (path: startsWith("/")) {
		formattedUrl: append(path: substring(1))
	} else {
		formattedUrl: append(path)
	}

	if (not path: endsWith("/")) {
		formattedUrl: append("/")
	}

	formattedUrl: append("?")

	return formattedUrl: toString()
}

local function createFormattedUrl = |url| {
	let formattedUrl = StringBuilder()
	if ((not url: startsWith("http://")) and (not url: startsWith("https://"))) {
		formattedUrl: append("http://")
	}
	formattedUrl: append(url)
	if (not url: endsWith("/")) {
		formattedUrl: append("/")
	}

	formattedUrl: append("?")
	
	return formattedUrl: toString()
}

# http://192.168.178.109/nixtape/2.0/?method=auth.gettoken&api_key=01234567890123456789012345678901&api_sig=01234567890123456789012345678901