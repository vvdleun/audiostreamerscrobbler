#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.Detector
import audiostreamerscrobbler.bluesound.Exceptions


function main = |args| {
	detectPlayer()
}

local function detectPlayer = {
	let players = detectBlueSoundPlayers(list["Woonkamer C368"])
	println(players)
}