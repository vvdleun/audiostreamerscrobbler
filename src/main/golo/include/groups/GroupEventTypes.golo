module audiostreamerscrobbler.groups.GroupEventTypes

union GroupEvents = {
	InitializationEvent
	DetectedEvent = { player }
	LostEvent = { player }
	PlayingEvent = { player }
	IdleEvent = { player }
}
