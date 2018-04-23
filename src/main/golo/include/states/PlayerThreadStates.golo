module audiostreamerscrobbler.states.PlayerThreadStates

union PlayerThreadStates = {
	DetectPlayer
	MonitorPlayer = { player }
}
