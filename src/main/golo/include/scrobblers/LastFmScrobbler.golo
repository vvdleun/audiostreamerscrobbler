module audiostreamerscrobbler.scrobbler.LastFmScrobbler

import audiostreamerscrobbler.scrobbler.AudioScrobbler20Impl

let SCROBBLER_ID = "lastfm"

let API_URL = "https://ws.audioscrobbler.com/2.0/"
let AUTH_URL = "https://last.fm/api/auth/"

let MAXIMAL_DAYS_OLD = 14

function getLastFmId = {
	return SCROBBLER_ID
}

function createLastFmScrobbler = |apiKey, apiSecret, sessionKey| {
	return createAudioScrobbler20Impl(SCROBBLER_ID, API_URL, apiKey, apiSecret, sessionKey, MAXIMAL_DAYS_OLD)
}

function createLastFmAuthorizer = |apiKey, apiSecret| {
	return createAudioScrobbler20AuthorizeHelper(SCROBBLER_ID, API_URL, AUTH_URL, apiKey, apiSecret)
}