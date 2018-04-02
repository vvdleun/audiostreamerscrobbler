module audiostreamerscrobbler.states.scrobbler.ScrobblerState

import audiostreamerscrobbler.states.types.StateTypes

function createScrobblerState = |previousState, scrobblersFactory, scrobblerAction| {
	let state = DynamicObject("ScrobblerState"):
		define("previousState", previousState):
		define("scrobblersFactory", scrobblersFactory):
		define("action", scrobblerAction):
		define("run", |this| -> runScrobblerState(this))
	return state
}

local function runScrobblerState = |scrobblerState| {
	let scrobblersFactory = scrobblerState: scrobblersFactory()
	let scrobblers = scrobblersFactory: createScrobblers()
	runScrobblerAction(scrobblers, scrobblerState: action())
	return StateTypes.NewState(scrobblerState: previousState())
}

local function runScrobblerAction = |scrobblers, action| {
	let song = action: Song()
	if (action: isUpdatePlayingNow()) {
		println("Update playing now...")
		updateNowPlaying(scrobblers, song)
	} else if (action: isScrobble()) {
		println("Scrobbling...")
		scrobble(scrobblers, song)
	} else {
		raise("Internal error: unknown action: " + action)
	}
}

local function updateNowPlaying = |scrobblers, song| {
	scrobblers: each(|scrobbler| {
		scrobbler: updateNowPlaying(song)
	})
}

local function scrobble = |scrobblers, song| {
	scrobblers: each(|scrobbler| {
		scrobbler: scrobble(song)
	})
}
