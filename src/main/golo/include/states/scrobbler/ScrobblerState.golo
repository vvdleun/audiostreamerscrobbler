module audiostreamerscrobbler.states.scrobbler.ScrobblerState

import audiostreamerscrobbler.maintypes.Config
import audiostreamerscrobbler.scrobbler.GnuFmScrobbler
import audiostreamerscrobbler.states.types.StateTypes


function createScrobblerState = |previousState, scrobblerAction| {
	let config = getConfig()
	let scrobblers = createScrobblers(config)
	let song = scrobblerAction: Song()
	
	let state = DynamicObject("ScrobblerState"):
		define("previousState", previousState):
		define("song", song):
		define("scrobblers", scrobblers):
		define("action", scrobblerAction):
		define("run", |this| -> runScrobblerAction(this))
	return state
}

local function createScrobblers = |config| {
	let scrobblers = list[]
	if (config: get("scrobblers"): containsKey("gnufm")) {
		let gnuFmConfig = config: get("scrobblers"): get("gnufm")
		let gnuFmScrobbler = createGnuFmScrobbler(gnuFmConfig: get("nixtapeUrl"), gnuFmConfig: get("sessionKey"))
		scrobblers: add(gnuFmScrobbler)
	}
	return scrobblers 
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
