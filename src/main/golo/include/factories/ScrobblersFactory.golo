module audiostreamerscrobbler.factories.ScrobblersFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.scrobbler.GnuFmScrobbler

let CONFIG_KEY_GNU_FM = "gnufm"

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
	if (isScrobblerEnabled(scrobblersConfig, CONFIG_KEY_GNU_FM)) {
		scrobblers: add(createGnuFMScrobblerInstance(scrobblersConfig))
	}
	return scrobblers 
}

local function createScrobblerAuthorizer = |configKey, config| {
	let scrobblersConfig = config: get("scrobblers")

	let returnInstance = -> match {
		when configKey == "gnufm" then createGnuFMAuthorizerInstance(scrobblersConfig)
		otherwise null
	}
	return returnInstance()
} 

local function isScrobblerEnabled = |scrobblersConfig, configKey| {
	return scrobblersConfig: getOrElse(configKey, map[]): getOrElse("enabled", false)
}

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