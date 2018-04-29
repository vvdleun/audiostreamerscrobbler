module audiostreamerscrobbler.players.musiccast.MusicCastDetector

import audiostreamerscrobbler.players.musiccast.MusicCastPlayer
import audiostreamerscrobbler.players.protocols.SSDPHandler
import audiostreamerscrobbler.states.detector.DetectorStateTypes.types.DetectorStateTypes
import audiostreamerscrobbler.utils.SimpleXMLParser

import java.lang.Thread
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

let SEARCH_TEXT_MUSICCAST = "urn:schemas-upnp-org:device:MediaRenderer:1"

let XML_YAMAHA_X_PATH = "root/yamaha:X_device"
let XML_YAMAHA_X_SERVICE_PATH = XML_YAMAHA_X_PATH + "/yamaha:X_serviceList/yamaha:X_service"
let XML_YAMAHA_X_SPEC_TYPE_PATH = XML_YAMAHA_X_SERVICE_PATH + "/yamaha:X_specType"
let XML_YAMAHA_X_CONTROL_URL_PATH = XML_YAMAHA_X_SERVICE_PATH + "/yamaha:X_yxcControlURL"

let XML_SPEC_TYPE_EXTENDED_CONTOL = "urn:schemas-yamaha-com:service:X_YamahaExtendedControl:1"

let XML_ELEMENTS_TO_KEYS = map[
	["root/device/manufacturer", "manufacturer"],
	["root/device/modelName", "model"],
	["root/device/friendlyName", "name"],
	["root/device/presentationURL", "host"],
	["root/yamaha:X_device/yamaha:X_URLBase", "urlBase"]]
	
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

			let uri = URL(headers: get("location"))

			let musicCastXml = map[]
			let service = map[["isService", false]]

			parseXmlElements(uri: openStream(), |event| {
				let path = event: path()

				if event: isStartElement() {
					if (path == XML_YAMAHA_X_PATH) {
						# MusicCast specs asks to validate explicitly that this element exists
						musicCastXml: put(XML_YAMAHA_X_PATH, true)
					} else if (path == XML_YAMAHA_X_SERVICE_PATH) {
						# Sub elements are parsed in the temporary "service" map
						service: put("isService", true)
					}
				} else if event: isEndElement() {
					if (path == XML_YAMAHA_X_SERVICE_PATH) {
						# Check whether this service was the one we were looking for
						if (service: get(XML_YAMAHA_X_SPEC_TYPE_PATH) == XML_SPEC_TYPE_EXTENDED_CONTOL) {
							musicCastXml: put("yxcControlUrl", service: get(XML_YAMAHA_X_CONTROL_URL_PATH))
						}
						service: clear()
						service: put("isService", false)

					} else if (service: get("isService")) {
						# Store sub elements of <yamaha:X_service> element in temporary "service" map
						service: put(path, event: characters())

					} else {
						# Map simple fields that need no additional parsing logic
						let key = XML_ELEMENTS_TO_KEYS: get(path)
						if key != null {
							musicCastXml: put(key, event: characters())
						}
					}
				}
			})
			detector: _isInitialized(true)

			if (_isMusicCastDevice(musicCastXml) and (musicCastXml: get("name") == playerName)) {
				keepSearching: set(false)
				devices: add(musicCastXml)
			}
		})
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

local function _isMusicCastDevice = |musicCastXml| {
	return (musicCastXml: get(XML_YAMAHA_X_PATH) == true and 
		musicCastXml: get("manufacturer") == "Yamaha Corporation" and 
		musicCastXml: get("urlBase") isnt null and 
		musicCastXml: get("yxcControlUrl") isnt null)
}

local function _createMusicCastImpl = |musicCastXml| {
	return MusicCastImpl(
		musicCastXml: get("name"),
		musicCastXml: get("model"),
		musicCastXml: get("manufacturer"),
		musicCastXml: get("host"),
		musicCastXml: get("urlBase"),
		musicCastXml: get("yxcControlUrl")
	)
}