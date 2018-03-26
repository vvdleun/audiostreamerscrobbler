module audiostreamerscrobbler.state.MonitorPlayerState

import audiostreamerscrobbler.state.StateManager
import audiostreamerscrobbler.monitor.types.MonitorStates

import java.lang.Thread

function createMonitorPlayerState = |player| {
	let state = DynamicObject("MonitorPlayerState"):
		define("_player", player):
		define("run", |this| -> runMonitorPlayerState(this: _player()))
	return state
}

local function runMonitorPlayerState = |player| {
	var monitorState = MonitorStates.MONITOR_KEEP_RUNNING()
	while (monitorState == MonitorStates.MONITOR_KEEP_RUNNING()) {
		monitorState = player: monitorPlayer()
	}
	return StateManager.STATE_HALT()
}