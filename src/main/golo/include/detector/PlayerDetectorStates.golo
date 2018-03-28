module audiostreamerscrobbler.detector

union PlayerDetectorStates = {
	playerNotFoundKeepTrying
	playerFound = { player }
}
