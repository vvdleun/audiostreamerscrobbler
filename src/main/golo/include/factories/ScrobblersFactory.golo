module audiostreamerscrobbler.factories.ScrobblersFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.scrobbler.GnuFmScrobbler
import audiostreamerscrobbler.scrobbler.LastFmScrobbler
import audiostreamerscrobbler.scrobbler.LibreFmScrobbler
import audiostreamerscrobbler.scrobbler.Scrobblers

let LAST_FM_ID = getLastFmId()
let LIBRE_FM_ID = getLibreFmId()
let GNU_FM_ID = getGnuFmId()

let SCROBBLER_IDS = [LAST_FM_ID, LIBRE_FM_ID, GNU_FM_ID]

function getScrobblerKeyNames = -> SCROBBLER_IDS

function createScrobblersFactory = {
	let config = getConfig()

	let scrobblersFactory = DynamicObject("ScrobblersFactory"):
		define("_config", config):
		define("createScrobblers", |this| -> createConfiguredScrobblers(this: _config())):
		define("createScrobbler", |this, id| -> createConfiguredScrobbler(id, this: _config())):
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
	if (id == LAST_FM_ID and isScrobblerEnabled(scrobblersConfig, LAST_FM_ID)) {
		return createLastFMScrobblerInstance(scrobblersConfig)
	}
	if (id == LIBRE_FM_ID and isScrobblerEnabled(scrobblersConfig, LIBRE_FM_ID)) {
		return createLibreFMScrobblerInstance(scrobblersConfig)
	}
	if (id == GNU_FM_ID and isScrobblerEnabled(scrobblersConfig, GNU_FM_ID)) {
		return createGnuFMScrobblerInstance(scrobblersConfig)
	}

	return null
}

local function createScrobblerAuthorizer = |id, config| {
	let scrobblersConfig = config: get("scrobblers")

	let returnInstance = -> match {
		when id == LAST_FM_ID then createLastFMAuthorizerInstance(scrobblersConfig)
		when id == LIBRE_FM_ID then createLibreFMAuthorizerInstance(scrobblersConfig)
		when id == GNU_FM_ID then createGnuFMAuthorizerInstance(scrobblersConfig)
		otherwise null
	}
	return returnInstance()
} 

local function isScrobblerEnabled = |scrobblersConfig, id| {
	return scrobblersConfig: getOrElse(id, map[]): getOrElse("enabled", false)
}

# Last FM

local function createLastFMScrobblerInstance = |scrobblersConfig| {
	let lastFmConfig = scrobblersConfig: get(LAST_FM_ID)
	let apiKey = lastFmConfig: get("apiKey") 
	let apiSecret = lastFmConfig: get("apiSecret") 
	let sessionKey = lastFmConfig: get("sessionKey") 
	return createLastFmScrobbler(apiKey, apiSecret, sessionKey)
}

local function createLastFMAuthorizerInstance = |scrobblersConfig| {
	let lastFmConfig = scrobblersConfig: get(LAST_FM_ID)
	if (lastFmConfig: get("apiKey") is null or lastFmConfig: get("apiSecret") is null) {
		throw "ERROR: Scrobbler 'lastfm' is not configured in config.json. Entries 'apiKey' and 'apiSecret' must be filled before authorization can take place."
	}

	let apiKey = lastFmConfig: get("apiKey") 
	let apiSecret = lastFmConfig: get("apiSecret") 
	return createLastFmAuthorizer(apiKey, apiSecret) 
}

# Libre FM

local function createLibreFMScrobblerInstance = |scrobblersConfig| {
	let libreFmConfig = scrobblersConfig: get(LIBRE_FM_ID)
	return createLibreFmScrobbler(libreFmConfig: get("sessionKey"))
}

local function createLibreFMAuthorizerInstance = |scrobblersConfig| {
	return createLibreFmAuthorizor() 
}

# GNU FM

local function createGnuFMScrobblerInstance = |scrobblersConfig| {
	let gnuFmConfig = scrobblersConfig: get(GNU_FM_ID)
	return createGnuFmScrobbler(gnuFmConfig: get("nixtapeUrl"), gnuFmConfig: get("sessionKey"))
}

local function createGnuFMAuthorizerInstance = |scrobblersConfig| {
	let gnuFmConfig = scrobblersConfig: get(GNU_FM_ID)
	if (gnuFmConfig: get("nixtapeUrl") is null) {
		throw "ERROR: Scrobbler 'gnufm' is not configured in config.json. Entry 'urlNixtape' in 'gnufm' entry must be filled before authorization can take place."
	}
	return createGnuFmAuthorizor(gnuFmConfig: get("nixtapeUrl")) 
}