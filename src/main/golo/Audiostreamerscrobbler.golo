#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.BlueSoundPlayerDetector
import audiostreamerscrobbler.bluesound.BlueSoundPlayer
import audiostreamerscrobbler.maintypes.Config
import audiostreamerscrobbler.states.detector.PlayerDetectorState
import audiostreamerscrobbler.states.StateManager


function main = |args| {
	let config = getConfig()
	let playerName = config: get("player"): get("name")
	let detector = createBlueSoundPlayerDetector(playerName)
	let initialState = createPlayerDetectorState(detector)
	let stateManager = createStateManager(initialState)
	while (stateManager: hasState()) {
		stateManager: run()
	}
}