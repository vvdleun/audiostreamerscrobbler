module audiostreamerscrobbler.monitor

union MonitorStates = {
	MONITOR_PLAYER
	MONITOR_SONG = { Song }
	MONITOR_LOST_PLAYER
	MONITOR_SCROBBLE = { Song }
}
