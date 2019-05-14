module audiostreamerscrobbler.players.musiccast.MusicCastMonitor

import audiostreamerscrobbler.maintypes.AppMetadata
import audiostreamerscrobbler.maintypes.SongType.types.Song
import audiostreamerscrobbler.threads.PlayerMonitorThreadTypes.types.MonitorThreadTypes
import audiostreamerscrobbler.utils.{NetworkUtils, UrlUtils, ThreadUtils}

import java.net.{DatagramPacket, SocketTimeoutException}
import java.util.concurrent.atomic.AtomicBoolean

let API_PLAY_INFO_PATH = "netusb/getPlayInfo"
let MAX_TIMEOUTS = 6

function createMusicCastMonitor = |player, socketFactory, httpRequestFactory, cb| {
	let musicCastImpl = player: musicCastImpl()
	
	let baseUrl = musicCastImpl: urlBase()
	let controlPath = musicCastImpl: yxcControlUrl()
	let apiUrl = createFormattedUrl(baseUrl, controlPath)
	
	let playInfoUrl = apiUrl + API_PLAY_INFO_PATH
	
	let appMetadata = getAppMetaData()

	let socketUpdates = socketFactory: createDatagramSocketAnyPort()
	socketUpdates: setSoTimeout(10 * 1000)
	
	let isRunning = AtomicBoolean(false)

	httpRequestFactory: customProperties(map[
		["X-AppName", "MusicCast/" + appMetadata: platform() + "(" + appMetadata: appVersion() + ")"],
		["X-AppPort", socketUpdates: localPort(): toString()]
	])
	let httpRequest = httpRequestFactory: createHttpRequest()

	let monitor = DynamicObject("MusicCastPlayerMonitor"):
		define("_cb", |this| -> cb):
		define("_httpRequest", |this| -> httpRequest):
		define("_playInfoUrl", |this| -> playInfoUrl):
		define("_socketUpdates", |this| -> socketUpdates):
		define("_isRunning", isRunning):
		define("_thread", null):
		define("_song", null):
		define("_lastSuccess", false):
		define("_timeouts", 0):
		define("player", |this| -> player):
		define("start", |this| -> startMonitor(this)):
		define("stop", |this| -> stopMonitor(this))

	return monitor
}

local function startMonitor = |monitor| {
	monitor: _isRunning(): set(true)

	# Do request, so that device starts sending its event updates via UDP
	getAndRegisterCurrentStatus(monitor)

	let thread = _createAndRunThread(monitor)
	monitor: _thread(thread)
 }

local function _createAndRunThread = |monitor| {
	println("Starting MusicCast player '" + monitor: player(): friendlyName() + "' monitor thread")
	return runInNewThread("MusicCastMonitorThread", {
		let socketUpdates = monitor: _socketUpdates()

		while (monitor: _isRunning(): get()) {
			try {
				# println("Waiting for data...")
				let answerBuffer = newTypedArray(byte.class, 1024 * 64)
				let answerPacket = DatagramPacket(answerBuffer, answerBuffer: length())

				socketUpdates: receive(answerPacket)
				
				let statusString = String(answerPacket: getData(), "utf-8"): trim()
				let status = JSON.parse(statusString)
				
				let netUsbStatus = status: get("netusb")
				# println(netUsbStatus)
				if (netUsbStatus isnt null) {
					var song = null
					if (netUsbStatus: containsKey("play_info_updated")) {
						song = getAndRegisterCurrentStatus(monitor)
					} else if (netUsbStatus: containsKey("play_time")) {
						song = monitor: _song()
						if(song isnt null) {
							song: position(netUsbStatus: get("play_time"): intValue())
						}
					}

					# Inform MonitorThread about status
					let cb = monitor: _cb()
					if (song isnt null) {
						cb(MonitorThreadTypes.PlayingSong(song))
					} else {
						cb(MonitorThreadTypes.Monitoring())
					}
				}
			} catch (ex) {
				case {
					when ex oftype SocketTimeoutException.class {
						let tooManyTimeouts = handleTimeouts(monitor)
						# println("TIMEOUTS: " + monitor: _timeouts())
						if (tooManyTimeouts) {
							# println("TOO MANY TIMEOUTS IN A ROW. POLLING PLAYER STATUS...")
							# This will update _lastSuccess() field
							getAndRegisterCurrentStatus(monitor) 
						}
						
						if (monitor: _lastSuccess()) {
							# println("PLAYER IS STILL ALIVE")
							let cb = monitor: _cb()
							cb(MonitorThreadTypes.Monitoring())
						}
					}
					otherwise {
						throw(ex)
					}
				}
			}
		}
		println("Stopped MusicCast player '" + monitor: player(): friendlyName() + "' monitor thread")
		socketUpdates: close()
	})
}

local function handleTimeouts = |monitor| {
	let timeouts = monitor: _timeouts() + 1
	if (timeouts >= MAX_TIMEOUTS) {
		monitor: _timeouts (0)
		return true
	} else {
		monitor: _timeouts(timeouts)
		return false
	}
}

local function stopMonitor = |monitor| {
	monitor: _isRunning(): set(false)
}

local function getAndRegisterCurrentStatus = |monitor| {
	try {
		let song = getNetUsbStatus(monitor)
		monitor: _lastSuccess(true)
		monitor: _song(song)
		return song
	} catch (ex) {
		throw(ex)
		monitor: _lastSuccess(false)
	}
	return null
 }

local function getNetUsbStatus = |monitor| {
	let playInfo = requestPlayInfo(monitor)
	validatePlayInfo(playInfo)
	if (not isPlayerPlaying(playInfo)) {
		return null
	}
	return convertPlayInfoToSong(playInfo)
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
	return Song(
		playInfo: get("track"), 
		playInfo: get("artist"),
		playInfo: get("album"),
		playInfo: get("play_time"): intValue(),
		playInfo: get("total_time"): intValue())
}