module audiostreamerscrobbler.scrobbler.ListenBrainz

import audiostreamerscrobbler.scrobbler.ListenBrainzApiImpl

let TRACKER_ID = "listenbrainz"

let API_URL = "https://api.listenbrainz.org/1/submit-listens"
let WEBSITE_URL = "https://listenbrainz.org/"

function getListenBrainzId = -> TRACKER_ID

function createListenBrainzTracker = |httpRequestFactory, userToken| {
	return createListenBrainzApiImpl(TRACKER_ID, httpRequestFactory, API_URL, userToken)
}

function createListenBrainzAuthorizor = {
	return createListenBrainzApiAuthorizor(TRACKER_ID, WEBSITE_URL)
}