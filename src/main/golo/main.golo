#!/usr/bin/env golosh
module Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.Detector


function main = |args| {
	detectPlayer()
}

local function detectPlayer = {
	detectPlayers(["Woonkamer C368"])
}