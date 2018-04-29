module audiostreamerscrobbler.players.musiccast.MusicCastDetector

import audiostreamerscrobbler.players.musiccast.MusicCastDeviceDescriptorXmlParser
import audiostreamerscrobbler.players.musiccast.MusicCastPlayer
import audiostreamerscrobbler.players.protocols.SSDPHandler
import audiostreamerscrobbler.states.detector.DetectorStateTypes.types.DetectorStateTypes

import java.lang.Thread
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

let SEARCH_TEXT_MUSICCAST = "urn:schemas-upnp-org:device:MediaRenderer:1"

function createMusicCastDetector = |playerName| {
	let detector = DynamicObject("MusicCastDetector"):
		define("_ssdpHandler", |this| -> getSsdpHandlerInstance()):
		define("_playerName", |this| -> playerName):
		define("_isInitialized", false):
		define("_keepSearching", AtomicBoolean(false)):
		define("detectPlayer", |this| -> discoverMusicCast(this))

	return detector
}

local function discoverMusicCast = |detector| {
	let ssdpHandler = detector: _ssdpHandler()

	let isInitialized = detector: _isInitialized()
	let keepSearching = detector: _keepSearching()
	let playerName = detector: _playerName()

	keepSearching: set(true)
	
	let devices = list[]
	
	if (not isInitialized) {
		# println("*** INITIALIZING ***")

		ssdpHandler: registerCallback(SEARCH_TEXT_MUSICCAST, |headers| {
			# This callback is supposed to be threadsafe thanks to Golang's Observable's
			# implementation...
			# println("CALLBACK: " + headers)
			if (not keepSearching: get()) {
				# println("Device is already found. Ignored incoming SSDP handler")
				# println(headers)
				return
			}

			let inputStream = URL(headers: get("location")): openStream()
			let deviceDescriptor = parseMusicCastDeviceDescriptorXML(inputStream)

			if (_isMusicCastDevice(deviceDescriptor) and (deviceDescriptor: name() == playerName)) {
				keepSearching: set(false)
				devices: add(deviceDescriptor)
			} else {
				println("Unknown device: " + deviceDescriptor)
			}
		})
		detector: _isInitialized(true)
	}

	ssdpHandler: start()
	
	while (keepSearching: get()) {
		foreach (i in range(3)) {
			if (not keepSearching: get()) {
				break
			}
			ssdpHandler: mSearch(SEARCH_TEXT_MUSICCAST, 1)
			Thread.sleep(1000_L)
		}
		if (keepSearching: get()) {
			Thread.sleep(10000_L)
		}
	}
	# println("Stopped search")
	
	ssdpHandler: stop()
	
	if (devices: size() > 0) {
		let musicCastImpl = _createMusicCastImpl(devices: get(0))
		let musicCastPlayer = createMusicCastPlayer(musicCastImpl)
	
		return DetectorStateTypes.PlayerFound(musicCastPlayer)
	} else {
		return DetectorStateTypes.PlayerNotFoundKeepTrying()
	}
}

local function _isMusicCastDevice = |deviceDescriptor| {
	return (deviceDescriptor: hasRequiredElement() == true and 
		deviceDescriptor: manufacturer() == "Yamaha Corporation" and
		deviceDescriptor: urlBase() isnt null and
		deviceDescriptor: yxcControlUrl() isnt null)
}

local function _createMusicCastImpl = |deviceDescriptor| {
	return MusicCastImpl(
		deviceDescriptor: name(),
		deviceDescriptor: model(),
		deviceDescriptor: manufacturer(),
		deviceDescriptor: host(),
		deviceDescriptor: urlBase(),
		deviceDescriptor: yxcControlUrl()
	)
}