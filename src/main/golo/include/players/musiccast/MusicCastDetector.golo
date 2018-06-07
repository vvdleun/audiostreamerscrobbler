module audiostreamerscrobbler.players.musiccast.MusicCastDetector

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes
import audiostreamerscrobbler.players.musiccast.{MusicCastPlayer, MusicCastDeviceDescriptorXmlParser}
import audiostreamerscrobbler.players.protocols.SSDPHandler

import java.net.URL

let SEARCH_TEXT_MUSICCAST = "urn:schemas-upnp-org:device:MediaRenderer:1"

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
		let inputStream = URL(headers: get("location")): openStream()
		let deviceDescriptor = parseMusicCastDeviceDescriptorXML(inputStream)

		if (_isMusicCastDevice(deviceDescriptor)) {
			let musicCastImpl = _createMusicCastImpl(deviceDescriptor)
			let musicCastPlayer = createMusicCastPlayer(musicCastImpl)
			cb(musicCastPlayer)
		} else {
			println("Unsupported or unknown device: " + deviceDescriptor)
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
