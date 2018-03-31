module audiostreamerscrobbler.states.monitor

# MonitorStates
union MonitorStateTypes = {
	MonitorRetry
	MonitorPlayer
	MonitorSong = { Song }
	MonitorLostPlayer
	MONITOR_SCROBBLE = { Song }
}
