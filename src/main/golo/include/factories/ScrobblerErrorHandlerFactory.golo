module audiostreamerscrobbler.factories.ScrobblerErrorHandlerFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.scrobbler.MissedScrobblerHandler

function createScrobblerErrorHandlerFactory = |scrobblers| {
	let config = getConfig()

	let scrobblerErrorHandlerFactory = DynamicObject("ScrobblerErrorHandlerFactory"):
		define("_config", config):
		define("_scrobblers", scrobblers):
		define("createScrobblerErrorHandler", |this| -> createScrobblerErrorHandler(this: _config(), this: _scrobblers()))
	
	return scrobblerErrorHandlerFactory
}
	
function createScrobblerErrorHandler = |config, scrobblers| {
	let errorHandlingSettings = config: get("settings"): get("errorHandling")
	let maxSongs = errorHandlingSettings: get("maxSongs")
	let retryIntervalMinutes = errorHandlingSettings: get("retryIntervalMinutes")
	return createMissedScrobblerHandlerThread(maxSongs, retryIntervalMinutes * 60, scrobblers)
}