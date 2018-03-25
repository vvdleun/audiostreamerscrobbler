#!/usr/bin/env golosh
module audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.Detector


function main = |args| {
	detectPlayer()
}

local function detectPlayer = {
	detectPlayers(["Woonkamer C368"])
}