#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.BlueSoundPlayerDetector
import audiostreamerscrobbler.bluesound.BlueSoundPlayer
import audiostreamerscrobbler.states.detector.PlayerDetectorState
import audiostreamerscrobbler.states.StateManager

function main = |args| {
	let detector = createBlueSoundPlayerDetector()
	let initialState = createPlayerDetectorState(detector)
	let stateManager = createStateManager(initialState)
	while (stateManager: hasState()) {
		stateManager: run()
	}
}