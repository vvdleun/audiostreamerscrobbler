module audiostreamerscrobbler.maintypes.Config

function getConfig = {
	let configText = fileToText("config.json", "UTF-8")
	return JSON.parse(configText)
}