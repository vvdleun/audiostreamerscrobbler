module audiostreamerscrobbler.factories.ScrobblersFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.scrobbler.GnuFmScrobbler
import audiostreamerscrobbler.scrobbler.LastFmScrobbler
import audiostreamerscrobbler.scrobbler.LibreFmScrobbler
import audiostreamerscrobbler.scrobbler.Scrobblers

let CONFIG_KEY_LAST_FM = getLastFmId()
let CONFIG_KEY_LIBRE_FM = getLibreFmId()
let CONFIG_KEY_GNU_FM = getGnuFmId()

let SCROBBLER_IDS = [CONFIG_KEY_LAST_FM, CONFIG_KEY_LIBRE_FM, CONFIG_KEY_GNU_FM]

function getScrobblerKeyNames = -> SCROBBLER_IDS

function createScrobblersFactory = {
	let config = getConfig()

	let scrobblersFactory = DynamicObject("ScrobblersFactory"):
		define("_config", config):
		define("createScrobblers", |this| -> createConfiguredScrobblers(this: _config())):
		define("createScrobbler", |this, id| -> createConfiguredScrobbler(id, this: _config())):
		define("createScrobblerAuthorizer", |this, configKey| -> createScrobblerAuthorizer(configKey, this: _config()))
	
	return scrobblersFactory
}

local function createConfiguredScrobblers = |config| {
	let scrobblers = list[]
	
	let scrobblersConfig = config: get("scrobblers")
	SCROBBLER_IDS: each(|s| {
		let scrobbler = createConfiguredScrobbler(scrobblersConfig, s)
		if (scrobbler != null) {
			scrobblers: add(scrobbler)
		}			
	})
	
	return [s foreach s in scrobblers]
}

local function createConfiguredScrobbler = |scrobblersConfig, id| {
	if (id == CONFIG_KEY_LAST_FM and isScrobblerEnabled(scrobblersConfig, CONFIG_KEY_LAST_FM)) {
		return createLastFMScrobblerInstance(scrobblersConfig)
	}
	if (id == CONFIG_KEY_LIBRE_FM and isScrobblerEnabled(scrobblersConfig, CONFIG_KEY_LIBRE_FM)) {
		return createLibreFMScrobblerInstance(scrobblersConfig)
	}
	if (id == CONFIG_KEY_GNU_FM and isScrobblerEnabled(scrobblersConfig, CONFIG_KEY_GNU_FM)) {
		return createGnuFMScrobblerInstance(scrobblersConfig)
	}

	return null
}

local function createScrobblerAuthorizer = |configKey, config| {
	let scrobblersConfig = config: get("scrobblers")

	let returnInstance = -> match {
		when configKey == CONFIG_KEY_LAST_FM then createLastFMAuthorizerInstance(scrobblersConfig)
		when configKey == CONFIG_KEY_LIBRE_FM then createLibreFMAuthorizerInstance(scrobblersConfig)
		when configKey == CONFIG_KEY_GNU_FM then createGnuFMAuthorizerInstance(scrobblersConfig)
		otherwise null
	}
	return returnInstance()
} 

local function isScrobblerEnabled = |scrobblersConfig, configKey| {
	return scrobblersConfig: getOrElse(configKey, map[]): getOrElse("enabled", false)
}

# Last FM

local function createLastFMScrobblerInstance = |scrobblersConfig| {
	let lastFmConfig = scrobblersConfig: get(CONFIG_KEY_LAST_FM)
	let apiKey = lastFmConfig: get("apiKey") 
	let apiSecret = lastFmConfig: get("apiSecret") 
	let sessionKey = lastFmConfig: get("sessionKey") 
	return createLastFmScrobbler(apiKey, apiSecret, sessionKey)
}

local function createLastFMAuthorizerInstance = |scrobblersConfig| {
	let lastFmConfig = scrobblersConfig: get(CONFIG_KEY_LAST_FM)
	if (lastFmConfig: get("apiKey") is null or lastFmConfig: get("apiSecret") is null) {
		throw "ERROR: Scrobbler 'lastfm' is not configured in config.json. Entries 'apiKey' and 'apiSecret' must be filled before authorization can take place."
	}

	let apiKey = lastFmConfig: get("apiKey") 
	let apiSecret = lastFmConfig: get("apiSecret") 
	return createLastFmAuthorizer(apiKey, apiSecret) 
}

# Libre FM

local function createLibreFMScrobblerInstance = |scrobblersConfig| {
	let libreFmConfig = scrobblersConfig: get(CONFIG_KEY_LIBRE_FM)
	return createLibreFmScrobbler(libreFmConfig: get("sessionKey"))
}

local function createLibreFMAuthorizerInstance = |scrobblersConfig| {
	return createLibreFmAuthorizor() 
}

# GNU FM

local function createGnuFMScrobblerInstance = |scrobblersConfig| {
	let gnuFmConfig = scrobblersConfig: get(CONFIG_KEY_GNU_FM)
	return createGnuFmScrobbler(gnuFmConfig: get("nixtapeUrl"), gnuFmConfig: get("sessionKey"))
}

local function createGnuFMAuthorizerInstance = |scrobblersConfig| {
	let gnuFmConfig = scrobblersConfig: get(CONFIG_KEY_GNU_FM)
	if (gnuFmConfig: get("nixtapeUrl") is null) {
		throw "ERROR: Scrobbler 'gnufm' is not configured in config.json. Entry 'urlNixtape' in 'gnufm' entry must be filled before authorization can take place."
	}
	return createGnuFmAuthorizor(gnuFmConfig: get("nixtapeUrl")) 
}