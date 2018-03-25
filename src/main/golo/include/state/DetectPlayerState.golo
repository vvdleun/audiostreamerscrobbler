module audiostreamerscrobbler.state.DetectPlayerState

import audiostreamerscrobbler.state.MonitorPlayerState

function createDetectPlayerState = |detector| {
	let state = DynamicObject("DetectPlayerState"):
		define("_detector", detector):
		define("run", |this| {
			let player = this: _detector(): detectPlayer()
			if (player is null) {
				return this
			}
			println("Found player: " + player)
			return createMonitorPlayerState(player)
		})

	return state
}



