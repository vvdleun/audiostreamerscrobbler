module audiostreamerscrobbler.groups.FixedPlayersGroupStrategy

function createFixedPlayersGroupStrategy = |playerIds| {
	let strategy = DynamicObject("FixedPlayersGroupStrategy"):
		define("_playerIds", playerIds):
		define("event", |this, group, event| -> event(this, group, event))

	return strategy
}

local function event = |strategy, group, event| {
	case {
		when event: isDetectedEvent() {
			handleDetectedEvent(strategy, group, event)
		}
		when event: isLostEvent() {

		}
		when event: isPlayingEvent() {

		}
		when event: isIdleEvent() {

		}
		otherwise {
			raise("Internal error: unknown group event '" + event + "'")
		}
	}
}

local function handleDetectedEvent = |strategy, group, event| {
	let player = event: player()

	# Not interested in events of players that are not managed by this group
	if (not strategy: _playerIds(): contains(player: id())) {
		return
	}

}
