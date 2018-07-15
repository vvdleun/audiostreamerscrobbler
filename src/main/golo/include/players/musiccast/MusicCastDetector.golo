module audiostreamerscrobbler.players.musiccast.MusicCastDetector

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes
import audiostreamerscrobbler.players.musiccast.{MusicCastPlayer, MusicCastDeviceDescriptorXmlParser}
import audiostreamerscrobbler.players.protocols.SSDPHandler

import java.net.URL

let SEARCH_TEXT_MUSICCAST = "urn:schemas-upnp-org:device:MediaRenderer:1"
let DEBUG = false

function createMusicCastDetector = |cb| {
	let ssdpHandler = getSsdpHandlerInstance()
	let ssdpCb = createSsdpCallback(ssdpHandler, cb)

	let detector = DynamicObject("MusicCastDetector"):
		define("_ssdpHandler", |this| -> ssdpHandler):
		define("_cb", |this| -> cb):
		define("_ssdpCb", |this| -> ssdpCb):
		define("playerType", PlayerTypes.MusicCast()):
		define("start", |this| -> startMusicCastDetector(this)):
		define("stop", |this| -> stopMusicCastDetector(this))
		
	return detector
}

local function createSsdpCallback = |ssdpHandler, cb| {
	let ssdpCb = |headers| {
		try {
			let deviceDescriptorUrl = headers: get("location")
			if (deviceDescriptorUrl isnt null) {
				let inputStream = URL(deviceDescriptorUrl): openStream()
				let deviceDescriptor = parseMusicCastDeviceDescriptorXML(inputStream)

				if (_isMusicCastDevice(deviceDescriptor)) {
					let musicCastImpl = _createMusicCastImpl(deviceDescriptor)
					let musicCastPlayer = createMusicCastPlayer(musicCastImpl)
					cb(musicCastPlayer)
				} else {
					if (DEBUG) {
						println("Device could not be validated as valid MusicCast device")
					}
				}
			} else {
				if (DEBUG) {
					println("No Device Descriptor URL found in HTML header. This is not a supported MusicCast device.")
				}
			}
		} catch(ex) {
			println("Error while processing SSDP incoming data: " + ex)
			throw(ex)
		}
	}
	return ssdpCb
}

local function startMusicCastDetector = |detector| {
	let ssdpHandler = detector: _ssdpHandler()
	ssdpHandler: addCallback(SEARCH_TEXT_MUSICCAST, detector: _ssdpCb())
}

local function stopMusicCastDetector = |detector| {
	let ssdpHandler = detector: _ssdpHandler()
	
	ssdpHandler: removeCallback(SEARCH_TEXT_MUSICCAST, detector: _ssdpCb())
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
