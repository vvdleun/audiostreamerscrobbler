#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.Detector
import audiostreamerscrobbler.bluesound.BlueSoundPlayerFactory
import audiostreamerscrobbler.state.PlayerDetectorState
import audiostreamerscrobbler.state.StateManager

function main = |args| {
	let detector = createBlueSoundDetector()
	let playerFactory = createBlueSoundPlayerFactory()
	let state = createPlayerDetectorState(detector, playerFactory)
	let stateManager = createStateManager(state)
	while (stateManager: hasState()) {
		stateManager: run()
	}
}