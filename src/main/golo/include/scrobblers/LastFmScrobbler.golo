module audiostreamerscrobbler.scrobbler.LastFmScrobbler

import audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl

let SCROBBLER_NAME = "LastFM"

let API_URL = "https://ws.audioscrobbler.com/2.0/"
let AUTH_URL = "https://last.fm/api/auth/"

function createLastFmScrobbler = |apiKey, apiSecret, sessionKey| {
	return createAudioScrobbler20Impl(SCROBBLER_NAME, API_URL, apiKey, apiSecret, sessionKey)
}

function createLastFmAuthorizer = |configKey, apiKey, apiSecret| {
	return createAudioScrobbler20AuthorizeHelper(configKey, API_URL, AUTH_URL, apiKey, apiSecret)
}