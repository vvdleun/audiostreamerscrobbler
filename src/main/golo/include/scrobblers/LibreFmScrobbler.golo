module audiostreamerscrobbler.scrobbler.LibreFmScrobbler

import audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl
import audiostreamerscrobbler.scrobbler.GnuFmScrobbler

let SCROBBLER_ID = "librefm"

let API_URL = "https://libre.fm/2.0/"
let AUTH_URL = "https://libre.fm/api/auth/"

function getLibreFmId = {
	return SCROBBLER_ID
}

function createLibreFmScrobbler = |sessionKey| {
	# Libre FM is a re-branded GNU FM hosted as a cloud service by the authors of GNU FM
	let apiKeyAndApiSecret = GnuFmScrobbler.getApiKeyAndSecret()
	let apiKey = apiKeyAndApiSecret: get(0)
	let apiSecret = apiKeyAndApiSecret: get(1)

	return createAudioScrobbler20Impl(SCROBBLER_ID, API_URL, apiKey, apiSecret, sessionKey)
}

function createLibreFmAuthorizor = {
	let apiKeyAndApiSecret = GnuFmScrobbler.getApiKeyAndSecret()
	let apiKey = apiKeyAndApiSecret: get(0)
	let apiSecret = apiKeyAndApiSecret: get(1)

	return createAudioScrobbler20AuthorizeHelper(SCROBBLER_ID, API_URL, AUTH_URL, apiKey, apiSecret)
}