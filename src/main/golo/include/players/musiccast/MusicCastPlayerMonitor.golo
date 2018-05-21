module audiostreamerscrobbler.players.musiccast.MusicCastPlayerMonitor

import audiostreamerscrobbler.maintypes.AppMetadata
import audiostreamerscrobbler.maintypes.Song
import audiostreamerscrobbler.states.monitor.types.MonitorStateTypes
import audiostreamerscrobbler.utils.UrlUtils

import java.net.{DatagramSocket, DatagramPacket, SocketTimeoutException}

let API_PLAY_INFO_PATH = "netusb/getPlayInfo"

function createMusicCastPlayerMonitor = |player, httpRequestFactory| {
	let musicCastImpl = player: playerType(): musicCastImpl()
	
	let baseUrl = musicCastImpl: urlBase()
	let controlPath = musicCastImpl: yxcControlUrl()
	let apiUrl = createFormattedUrl(baseUrl, controlPath)
	
	let playInfoUrl = apiUrl + API_PLAY_INFO_PATH
	
	let appMetadata = getAppMetaData()

	let socketUpdates = DatagramSocket()
	
	httpRequestFactory: customProperties(map[
		["X-AppName", "MusicCast/" + appMetadata: platform() + "(" + appMetadata: appVersion() + ")"],
		["X-AppPort", socketUpdates: localPort(): toString()]
	])
	let httpRequest = httpRequestFactory: createHttpRequest()
	
	let monitor = DynamicObject("MusicCastPlayerMonitor"):
		define("_httpRequest", |this| -> httpRequest):
		define("_playInfoUrl", |this| -> playInfoUrl):
		define("_socketUpdates", |this| -> socketUpdates):
		define("player", |this| -> player):
		define("monitorPlayer", |this| -> monitorPlayer(this)):
		define("stopMonitor", |this| -> stopMonitor(this))

	return monitor
}

local function monitorPlayer = |monitor| {
	let socketUpdates = monitor: _socketUpdates()
	socketUpdates: setSoTimeout(10 * 1000)

	let playInfo = requestPlayInfo(monitor)

	try {
		while (true) {
			println("Waiting for data...")
			let answerBuffer = newTypedArray(byte.class, 1024 * 16)
			let answerPacket = DatagramPacket(answerBuffer, answerBuffer: length())

			socketUpdates: receive(answerPacket)
			println("Received: " + String(answerPacket: getData(), "utf-8"))
		}
	} catch (ex) {
		case {
			when ex oftype SocketTimeoutException.class {
				println("MusicCast Update Timeout")
				return MonitorStateTypes.MonitorPlayer()
			}
			otherwise {
				throw(ex)
			}
		}
	}

	# validatePlayInfo(playInfo)
	
	# if (not isPlayerPlaying(playInfo)) {
	# 	return MonitorStateTypes.MonitorPlayer()
	# }
	
	# let song = convertPlayInfoToSong(playInfo)
	# return MonitorStateTypes.MonitorSong(song)	
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

function stopMonitor = |monitor| {
	
}