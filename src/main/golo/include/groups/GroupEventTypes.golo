module audiostreamerscrobbler.groups.GroupEventTypes

union GroupEvents = {
	DetectedEvent = { player }
	LostEvent = { player }
	PlayingEvent = { player }
	IdleEvent = { player }
}
