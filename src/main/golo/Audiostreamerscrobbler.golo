#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.factories.PlayerDetectorFactory
import audiostreamerscrobbler.factories.ScrobblersFactory
import audiostreamerscrobbler.states.detector.PlayerDetectorState
import audiostreamerscrobbler.states.StateManager


function main = |args| {
	
	let playerDetectorFactory = createPlayerDetectorFactory()
	let scrobblersFactory = createScrobblersFactory()
	
	let initialState = createPlayerDetectorState(playerDetectorFactory, scrobblersFactory)
	let stateManager = createStateManager(initialState)
	while (stateManager: hasState()) {
		stateManager: run()
	}
}