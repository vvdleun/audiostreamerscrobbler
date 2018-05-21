module audiostreamerscrobbler.maintypes.AppMetadata

import java.lang.System

let APP_NAME = "AudioStreamerScrobbler"
let APP_VERSION = "0.01"

struct AppMetaData = {
	appName,
	appVersion,
	platform
}

function getAppMetaData = {
	let platform = System.getProperty("os.name")
	return AppMetaData(APP_NAME, APP_VERSION, platform)
}