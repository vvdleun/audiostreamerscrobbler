module audiostreamerscrobbler.states.detector.MainTypes

union DetectorStateTypes = {
	PlayerNotFoundKeepTrying
	PlayerFound = { Player }
}
