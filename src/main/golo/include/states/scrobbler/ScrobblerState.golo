module audiostreamerscrobbler.states.scrobbler.ScrobblerState

import audiostreamerscrobbler.states.types.StateTypes

function createScrobblerState = |previousState, song, scrobblers, scrobblerAction| {
	let state = DynamicObject("ScrobblerState"):
		define("previousState", previousState):
		define("song", song):
		define("scrobblers", scrobblers):
		define("action", scrobblerAction):
		define("run", |this| -> runScrobblerAction(this))
	return state
}

local function runScrobblerAction = |scrobblerState| {
	scrobblerState: scrobblers(): each(|scrobbler| {
		println("scrobbler action: " + scrobblerState: action())
		if (scrobblerState: action(): isUpdatePlayingNow()) {
			println("a")
			scrobbler: updateNowPlaying(scrobblerState: song())
		} else {
			println("b")
			scrobbler: scrobble(scrobblerState: song())
		}
	})
	return StateTypes.NewState(scrobblerState: previousState())

}
