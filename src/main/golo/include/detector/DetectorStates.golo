module audiostreamerscrobbler.detector

union DetectorStates = {
	DETECTOR_KEEP_RUNNING
	DETECTOR_MONITOR_PLAYER = { player }
}
