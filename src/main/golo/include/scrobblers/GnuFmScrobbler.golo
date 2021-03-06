module audiostreamerscrobbler.scrobbler.GnuFmScrobbler

import audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl
import audiostreamerscrobbler.utils.UrlUtils

let SCROBBLER_ID = "gnufm"

let API_KEY = "5190DEE005D346288EE891733C4F510A"
let API_NOT_SO_SECRET = "05FF369157CF42C1B566D3389CFD16D1"

let API_URL_PATH = "2.0/"
let API_AUTH_PATH = "api/auth/"

let MAXIMAL_DAYS_OLD = 30

function getGnuFmId = {
	return SCROBBLER_ID
}

function createGnuFmScrobbler = |httpRequest, nixtapeUrl, sessionKey| {
	let apiUrl = createApiUrl(nixtapeUrl)
	return createAudioScrobbler20Impl(SCROBBLER_ID, httpRequest, apiUrl, API_KEY, API_NOT_SO_SECRET, sessionKey, MAXIMAL_DAYS_OLD)
}

function createGnuFmAuthorizor = |httpRequest, nixtapeUrl| {
	let apiUrl = createApiUrl(nixtapeUrl)
	let authorizeUrl = createAuthorizeUrl(nixtapeUrl)
	return createAudioScrobbler20AuthorizeHelper(SCROBBLER_ID, httpRequest, apiUrl, authorizeUrl, API_KEY, API_NOT_SO_SECRET)
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