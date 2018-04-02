module audiostreamerscrobbler.factories.ScrobblersFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.scrobbler.GnuFmScrobbler
import audiostreamerscrobbler.scrobbler.LastFmScrobbler
import audiostreamerscrobbler.scrobbler.LibreFmScrobbler

let CONFIG_KEY_LAST_FM = "lastfm"
let CONFIG_KEY_LIBRE_FM = "librefm"
let CONFIG_KEY_GNU_FM = "gnufm"

let SCROBBLER_NAMES = [CONFIG_KEY_LAST_FM, CONFIG_KEY_GNU_FM, CONFIG_KEY_LIBRE_FM]

function getScrobblerKeyNames = -> SCROBBLER_NAMES

function createScrobblersFactory = {
	let config = getConfig()

	let scrobblersFactory = DynamicObject("ScrobblersFactory"):
		define("_config", config):
		define("createScrobblers", |this| -> createScrobblers(this: _config())):
		define("createScrobblerAuthorizer", |this, configKey| -> createScrobblerAuthorizer(configKey, this: _config()))
	
	return scrobblersFactory
}

local function createScrobblers = |config| {
	let scrobblers = list[]

	let scrobblersConfig = config: get("scrobblers")
	if (isScrobblerEnabled(scrobblersConfig, CONFIG_KEY_LAST_FM)) {
		scrobblers: add(createLastFMScrobblerInstance(scrobblersConfig))
	}
	if (isScrobblerEnabled(scrobblersConfig, CONFIG_KEY_LIBRE_FM)) {
		scrobblers: add(createLibreFMScrobblerInstance(scrobblersConfig))
	}
	if (isScrobblerEnabled(scrobblersConfig, CONFIG_KEY_GNU_FM)) {
		scrobblers: add(createGnuFMScrobblerInstance(scrobblersConfig))
	}

	return scrobblers 
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
	return createLastFmAuthorizer(CONFIG_KEY_LAST_FM, apiKey, apiSecret) 
}

# Libre FM

local function createLibreFMScrobblerInstance = |scrobblersConfig| {
	let libreFmConfig = scrobblersConfig: get(CONFIG_KEY_LIBRE_FM)
	return createLibreFmScrobbler(libreFmConfig: get("sessionKey"))
}

local function createLibreFMAuthorizerInstance = |scrobblersConfig| {
	return createLibreFmAuthorizor(CONFIG_KEY_LIBRE_FM) 
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
	return createGnuFmAuthorizor(CONFIG_KEY_GNU_FM, gnuFmConfig: get("nixtapeUrl")) 
}