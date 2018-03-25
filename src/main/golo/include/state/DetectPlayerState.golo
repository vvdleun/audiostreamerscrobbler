module audiostreamerscrobbler.state.DetectPlayerState

import audiostreamerscrobbler.state.MonitorPlayerState

function createDetectPlayerState = |detector| {
	let state = DynamicObject("DetectPlayerState"):
		define("_detector", detector):
		define("run", |this| -> runDetectPlayerState(this))
	return state
}

local function runDetectPlayerState = |state| {
	let detector = state: _detector()
	let player = detector: detectPlayer()
	if (player is null) {
		return state
	}
	println("Found player: " + player)
	return createMonitorPlayerState(player)

}


