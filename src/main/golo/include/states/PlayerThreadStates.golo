module audiostreamerscrobbler.states

union PlayerThreadStates = {
	DetectPlayer
	MonitorPlayer = { player }
	ScrobbleAction = { action, monitorState }
	PreviousState = { state }
}
