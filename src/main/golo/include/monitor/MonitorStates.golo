module audiostreamerscrobbler.monitor

union MonitorStates = {
	MONITOR_KEEP_RUNNING
	MONITOR_LOST_PLAYER
	MONITOR_SCROBBLE = { song }
}
