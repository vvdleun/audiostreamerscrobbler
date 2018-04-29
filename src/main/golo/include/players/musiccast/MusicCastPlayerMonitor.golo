module audiostreamerscrobbler.players.musiccast.MusicCastPlayerMonitor

import audiostreamerscrobbler.maintypes.Song.types.Song
import audiostreamerscrobbler.states.monitor.types.MonitorStateTypes
import audiostreamerscrobbler.utils.UrlUtils

let API_PLAY_INFO_PATH = "netusb/getPlayInfo"

function createMusicCastPlayerMonitor = |player, httpRequestFactory| {
	let musicCast = player: playerType(): musicCastImpl()
	
	let baseUrl = musicCast: urlBase()
	let controlPath = musicCast: yxcControlUrl()
	let apiUrl = createFormattedUrl(baseUrl, controlPath)
	
	let playInfoUrl = apiUrl + API_PLAY_INFO_PATH
	
	let httpRequest = httpRequestFactory: createHttpRequest()
	
	let monitor = DynamicObject("MusicCastPlayerMonitor"):
		define("_httpRequest", |this| -> httpRequest):
		define("_playInfoUrl", |this| -> playInfoUrl):
		define("player", |this| -> player):
		define("monitorPlayer", |this| -> monitorPlayer(this))

	return monitor
}

local function monitorPlayer = |monitor| {
	let playInfo = requestPlayInfo(monitor)

	validatePlayInfo(playInfo)
	
	if (not isPlayerPlaying(playInfo)) {
		return MonitorStateTypes.MonitorPlayer()
	}
	
	let song = convertPlayInfoToSong(playInfo)
	return MonitorStateTypes.MonitorSong(song)	
}

local function requestPlayInfo = |monitor| {
	let playInfoUrl = monitor: _playInfoUrl()
	
	# println("Requesting from '" + playInfoUrl + "'")
	
	let httpRequest = monitor: _httpRequest()
	return httpRequest: doHttpGetRequestAndReturnJSON(playInfoUrl)
}

local function validatePlayInfo = |playInfo| {
	let responseCode = playInfo: get("response_code")
	if not (responseCode == 0) {
		raise("Player information could not be obtained. Error code: " + responseCode)
	}
}

local function isPlayerPlaying = |playInfo| {
	return playInfo: get("playback") == "play"
}

local function convertPlayInfoToSong = |playInfo| {
	let song = Song(
		playInfo: get("track"), 
		playInfo: get("artist"),
		playInfo: get("album"),
		playInfo: get("play_time"): intValue(),
		playInfo: get("total_time"): intValue())
	return song
}