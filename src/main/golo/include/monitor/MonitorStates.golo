module audiostreamerscrobbler.monitor

union MonitorStates = {
	MONITOR_IGNORE_ITERATION
	MONITOR_PLAYER
	MONITOR_SONG = { Song }
	MONITOR_LOST_PLAYER = { Player }
	MONITOR_SCROBBLE = { Song }
}
