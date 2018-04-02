module audiostreamerscrobbler.states.scrobbler

union ScrobblerActionTypes = {
	UpdatePlayingNow = { Song }
	Scrobble = { Song }
}
