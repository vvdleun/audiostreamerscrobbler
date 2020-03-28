module audiostreamerscrobbler.groups.GroupProcessEventTypes

union GroupProcessEvents = {
	StartDetectors = { playerTypes }
	StopDetectors = { playerTypes }
	StartMonitors = { players }
	StopMonitors = { players }
}