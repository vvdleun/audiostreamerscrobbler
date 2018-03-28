module audiostreamerscrobbler.state.PlayerMonitorState

import audiostreamerscrobbler.monitor.types.MonitorStates
import audiostreamerscrobbler.state.StateManager
import audiostreamerscrobbler.state.types.StateStates

import java.lang.Thread

function createPlayerMonitorState = |player| {
	let state = DynamicObject("PlayerMonitorState"):
		define("_player", player):
		define("run", |this| -> runMonitorPlayerState(this: _player()))
	return state
}

local function runMonitorPlayerState = |player| {
	let playerMonitor = player: createMonitor()

	var monitorState = MonitorStates.MONITOR_KEEP_RUNNING()
	while (monitorState == MonitorStates.MONITOR_KEEP_RUNNING()) {
		monitorState = playerMonitor: monitorPlayer()
	}
	# Scrobbling state is not ready yet...
	return StateStates.HaltProgram()
}