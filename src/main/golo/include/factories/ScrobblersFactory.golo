module audiostreamerscrobbler.factories.ScrobblersFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.factories.RequestFactory
import audiostreamerscrobbler.scrobbler.GnuFmScrobbler
import audiostreamerscrobbler.scrobbler.LastFmScrobbler
import audiostreamerscrobbler.scrobbler.LibreFmScrobbler
import audiostreamerscrobbler.scrobbler.ListenBrainz
import audiostreamerscrobbler.scrobbler.ListenBrainzServer
import audiostreamerscrobbler.scrobbler.Scrobblers

let LAST_FM_ID = getLastFmId()
let LISTEN_BRAINZ_ID = getListenBrainzId()
let LISTEN_BRAINZ_SERVER_ID = getListenBrainzServerId()
let LIBRE_FM_ID = getLibreFmId()
let GNU_FM_ID = getGnuFmId()

let SCROBBLER_IDS = [LAST_FM_ID, LISTEN_BRAINZ_ID, LIBRE_FM_ID, GNU_FM_ID, LISTEN_BRAINZ_SERVER_ID]

function getScrobblerKeyNames = -> SCROBBLER_IDS

function createScrobblersFactory = {
	let config = getConfig()

	let scrobblersFactory = DynamicObject("ScrobblersFactory"):
		define("_config", config):
		define("createScrobblers", |this| -> createConfiguredScrobblers(this: _config())):
		define("createScrobblerAuthorizer", |this, id| -> createScrobblerAuthorizer(id, this: _config()))
	
	return scrobblersFactory
}

local function createConfiguredScrobblers = |config| {
	let scrobblers = list[]
	
	let scrobblersConfig = config: get("scrobblers")
	SCROBBLER_IDS: each(|id| {
		let scrobbler = createConfiguredScrobbler(scrobblersConfig, id)
		if (scrobbler != null) {
			scrobblers: add(scrobbler)
		}			
	})
	return [s foreach s in scrobblers]
}

local function createConfiguredScrobbler = |scrobblersConfig, id| {
	let createFunctions = map[
		[LAST_FM_ID, ^createLastFMScrobblerInstance],
		[LISTEN_BRAINZ_ID, ^createListenBrainzTrackerInstance],
		[LIBRE_FM_ID, ^createLibreFMScrobblerInstance],
		[GNU_FM_ID, ^createGnuFMScrobblerInstance],
		[LISTEN_BRAINZ_SERVER_ID, ^createListenBrainzServerTrackerInstance]]

	let createFunction = createFunctions: getOrElse(id, null)
	
	if (createFunction != null and isScrobblerEnabled(scrobblersConfig, id)) {
		return createFunction(scrobblersConfig)
	}

	return null
}

local function isScrobblerEnabled = |scrobblersConfig, id| {
	return scrobblersConfig: getOrElse(id, map[]): getOrElse("enabled", false)
}

local function createScrobblerAuthorizer = |id, config| {
	let scrobblersConfig = config: get("scrobblers")

	let returnInstance = -> match {
		when id == LAST_FM_ID then createLastFMAuthorizerInstance(scrobblersConfig)
		when id == LISTEN_BRAINZ_ID then createListenBrainzAuthorizerInstance()
		when id == LIBRE_FM_ID then createLibreFMAuthorizerInstance()
		when id == GNU_FM_ID then createGnuFMAuthorizerInstance(scrobblersConfig)
		when id == LISTEN_BRAINZ_SERVER_ID then createListenBrainzServerAuthorizerInstance(scrobblersConfig)
		otherwise null
	}
	return returnInstance()
} 

# Last FM

local function createLastFMScrobblerInstance = |scrobblersConfig| {
	let lastFmConfig = scrobblersConfig: get(LAST_FM_ID)
	let httpRequest = createHttpRequestFactory(): createHttpRequest()
	let apiKey = lastFmConfig: get("apiKey") 
	let apiSecret = lastFmConfig: get("apiSecret") 
	let sessionKey = lastFmConfig: get("sessionKey")
	return createLastFmScrobbler(httpRequest, apiKey, apiSecret, sessionKey)
}

local function createLastFMAuthorizerInstance = |scrobblersConfig| {
	let lastFmConfig = scrobblersConfig: get(LAST_FM_ID)
	if (lastFmConfig: get("apiKey") is null or lastFmConfig: get("apiSecret") is null) {
		throw "ERROR: Scrobbler '" + LAST_FM_ID + "' is not configured in config.json. Entries 'apiKey' and 'apiSecret' must be filled before authorization can take place."
	}

	let httpRequest = createHttpRequestFactory(): createHttpRequest()
	let apiKey = lastFmConfig: get("apiKey") 
	let apiSecret = lastFmConfig: get("apiSecret") 
	return createLastFmAuthorizer(httpRequest, apiKey, apiSecret) 
}

# ListenBrainz

local function createListenBrainzTrackerInstance = |scrobblersConfig| {
	let listenBrainzConfig = scrobblersConfig: get(LISTEN_BRAINZ_ID)
	let httpRequestFactory = createHttpRequestFactory()
	return createListenBrainzTracker(httpRequestFactory, listenBrainzConfig: get("userToken"))
}

local function createListenBrainzAuthorizerInstance = {
	return createListenBrainzAuthorizor()
}

# Libre FM

local function createLibreFMScrobblerInstance = |scrobblersConfig| {
	let libreFmConfig = scrobblersConfig: get(LIBRE_FM_ID)
	let httpRequest = createHttpRequestFactory(): createHttpRequest()
	return createLibreFmScrobbler(httpRequest, libreFmConfig: get("sessionKey"))
}

local function createLibreFMAuthorizerInstance = {
	let httpRequest = createHttpRequestFactory(): createHttpRequest()
	return createLibreFmAuthorizor(httpRequest) 
}

# GNU FM

local function createGnuFMScrobblerInstance = |scrobblersConfig| {
	let gnuFmConfig = scrobblersConfig: get(GNU_FM_ID)
	let httpRequest = createHttpRequestFactory(): createHttpRequest()
	return createGnuFmScrobbler(httpRequest, gnuFmConfig: get("nixtapeUrl"), gnuFmConfig: get("sessionKey"))
}

local function createGnuFMAuthorizerInstance = |scrobblersConfig| {
	let gnuFmConfig = scrobblersConfig: get(GNU_FM_ID)
	if (gnuFmConfig: get("nixtapeUrl") is null) {
		throw "ERROR: Scrobbler '" + GNU_FM_ID + "' is not configured in config.json. Fill its 'nixtapeUrl' entry and try again."
	}
	let httpRequest = createHttpRequestFactory(): createHttpRequest()
	return createGnuFmAuthorizor(httpRequest, gnuFmConfig: get("nixtapeUrl")) 
}

# ListenBrainz Server (local installation of ListenBrainz Server)

local function createListenBrainzServerTrackerInstance = |scrobblersConfig| {
	let listenBrainzServerConfig = scrobblersConfig: get(LISTEN_BRAINZ_SERVER_ID)
	let httpRequestFactory = createHttpRequestFactory()
	let apiUrl = listenBrainzServerConfig: get("apiUrl")
	let websiteUrl = listenBrainzServerConfig: get("websiteUrl")
	let userToken = listenBrainzServerConfig: get("userToken")
	return createListenBrainzServerTracker(httpRequestFactory, apiUrl, websiteUrl, userToken)
}

local function createListenBrainzServerAuthorizerInstance = |scrobblersConfig| {
	let listenBrainzServerConfig = scrobblersConfig: get(LISTEN_BRAINZ_SERVER_ID)
	let websiteUrl = listenBrainzServerConfig: get("websiteUrl")
	if (listenBrainzServerConfig: get("websiteUrl") is null) {
		throw "ERROR: Scrobbler '" + LISTEN_BRAINZ_SERVER_ID + "' is not configured in config.json. Entry 'websiteUrl' must be filled before authorization can take place."
	}

	return createListenBrainzServerAuthorizor(websiteUrl)
}