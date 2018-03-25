module audiostreamerscrobbler.state.MonitorPlayerState

import java.lang.Thread

function createMonitorPlayerState = |player| {
	let state = DynamicObject("MonitorPlayerState"):
		define("_player", player):
		define("run", |this| -> runMonitorPlayerState(this))
	return state
}

local function runMonitorPlayerState = |state| {
	while (true) {
		println("Dummy")
		Thread.sleep(10000_L)
	}
}