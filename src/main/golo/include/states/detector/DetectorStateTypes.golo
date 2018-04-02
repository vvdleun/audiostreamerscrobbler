module audiostreamerscrobbler.states.detector

union DetectorStateTypes = {
	PlayerNotFoundKeepTrying
	PlayerFound = { Player }
}
