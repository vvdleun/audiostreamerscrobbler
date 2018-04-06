module audiostreamerscrobbler.factories.Config

import gololang.IO

function getConfig = {
	let configText = fileToText("config.json", "UTF-8")
	return JSON.parse(configText)
}