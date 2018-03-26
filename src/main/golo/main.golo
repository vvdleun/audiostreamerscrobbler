#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.Detector
import audiostreamerscrobbler.state.DetectPlayerState
import audiostreamerscrobbler.state.StateManager

function main = |args| {
	let detector = createBlueSoundDetector()
	let state = createDetectPlayerState(detector)
	let stateManager = createStateManager(state)
	while (stateManager: hasState()) {
		stateManager: run()
	}
}