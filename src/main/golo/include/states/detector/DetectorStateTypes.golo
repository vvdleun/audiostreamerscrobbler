module audiostreamerscrobbler.states.detector

union DetectorStateTypes = {
	playerNotFoundKeepTrying
	playerFound = { player }
}
