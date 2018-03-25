#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.bluesound.Detector
import audiostreamerscrobbler.state.DetectPlayerState
import audiostreamerscrobbler.state.StateManager

import java.lang.Thread
import java.net.BindException


function main = |args| {
	let detector = createBlueSoundDetector()
	let state = createDetectPlayerState(detector)
	let stateManager = createStateManager(state)
	while (stateManager: hasState()) {
		stateManager: run()
	}
}

