module audiostreamerscrobbler.scrobbler.ListenBrainzServer

import audiostreamerscrobbler.scrobbler.ListenBrainzApiImpl
import audiostreamerscrobbler.utils.UrlUtils

let TRACKER_ID = "listenbrainz-server"

let API_URL_PATH = "/1/submit-listens"

function getListenBrainzServerId = -> TRACKER_ID

function createListenBrainzServerTracker = |httpRequestFactory, apiUrl, websiteUrl, userToken| {
	let formattedApiPath = createApiUrl(apiUrl, websiteUrl)
	return createListenBrainzApiImpl(TRACKER_ID, httpRequestFactory, formattedApiPath, userToken)
}

function createListenBrainzServerAuthorizor = |websiteUrl| {
	let formattedWebsiteUrl = createWebsiteUrl(websiteUrl)
	return createListenBrainzApiAuthorizor(TRACKER_ID, formattedWebsiteUrl)
}

# Listen Brainz Server URL builder functions

local function createApiUrl = |apiUrl, websiteUrl| {
	let baseUrl = match {
		when apiUrl isnt null and not apiUrl: isEmpty() then apiUrl
		otherwise websiteUrl
	}
	
	let url = createFormattedUrl(baseUrl, API_URL_PATH)
	return url: substring(0, url: length() - 1)
}

local function createWebsiteUrl = |websiteUrl| {
	return createFormattedUrl(websiteUrl)
}