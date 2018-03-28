#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.BlueSoundPlayerDetector
import audiostreamerscrobbler.bluesound.BlueSoundPlayer
import audiostreamerscrobbler.state.PlayerDetectorState
import audiostreamerscrobbler.state.StateManager

function main = |args| {
	let detector = createBlueSoundPlayerDetector()
	let playerFactory = createBlueSoundPlayerFactory()
	let initialState = createPlayerDetectorState(detector, playerFactory)
	let stateManager = createStateManager(initialState)
	while (stateManager: hasState()) {
		stateManager: run()
	}
}