module audiostreamerscrobbler.scrobbler.GnuFmScrobbler

import audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl

let SCROBBLER_NAME = "GnuFM"

let API_KEY = "5190DEE005D346288EE891733C4F510A"
let API_NOT_SO_SECRET = "05FF369157CF42C1B566D3389CFD16D1"

let API_URL_PATH = "2.0/"
let API_AUTH_PATH = "api/auth/"

function createGnuFmScrobbler = |nixtapeUrl, sessionKey| {
	let apiUrl = createApiUrl(nixtapeUrl)
	return createAudioScrobbler20Impl(SCROBBLER_NAME, apiUrl, API_KEY, API_NOT_SO_SECRET, sessionKey)
}

function createGnuFmAuthorizor = |configKey, nixtapeUrl| {
	let apiUrl = createApiUrl(nixtapeUrl)
	let authorizeUrl = createAuthorizeUrl(nixtapeUrl)
	return createAudioScrobbler20AuthorizeHelper(configKey, apiUrl, authorizeUrl, API_KEY, API_NOT_SO_SECRET)
}

function getApiKeyAndSecret = {
	return [API_KEY, API_NOT_SO_SECRET]
}

# GNU FM URL builder functions

local function createApiUrl = |nixtapeUrl| {
	return createFormattedUrl(nixtapeUrl, API_URL_PATH)
}

local function createAuthorizeUrl = |nixtapeUrl| {
	return createFormattedUrl(nixtapeUrl, API_AUTH_PATH)
}

# Low level URL builder functions

local function createFormattedUrl = |url, path| {
	let formattedUrl = StringBuilder()

	formattedUrl: append(createFormattedUrl(url))

	if (path: startsWith("/")) {
		formattedUrl: append(path: substring(1))
	} else {
		formattedUrl: append(path)
	}

	if (not path: endsWith("/")) {
		formattedUrl: append("/")
	}

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

	return formattedUrl: toString()
}