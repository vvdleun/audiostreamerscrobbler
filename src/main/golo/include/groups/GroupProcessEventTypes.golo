module audiostreamerscrobbler.groups.GroupProcessEventTypes

union GroupProcessEvents = {
	startDetectors = { playerTypes }
	stopDetectors = { playerTypes }
	stopMonitors = { players }
}