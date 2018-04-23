module audiostreamerscrobbler.states.detector.DetectorStateTypes

union DetectorStateTypes = {
	PlayerNotFoundKeepTrying
	PlayerFound = { Player }
}
