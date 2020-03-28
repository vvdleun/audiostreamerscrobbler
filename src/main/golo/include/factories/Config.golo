module audiostreamerscrobbler.factories.Config

import gololang.IO

var CONFIG = null

function initConfig = {
	CONFIG = _createConfig()
}

function getConfig = {
	return CONFIG
}

local function _createConfig = {
	let configText = fileToText("config.json", "UTF-8")
	return JSON.parse(configText)
}