module audiostreamerscrobbler.players.musiccast.MusicCastDetector

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes
import audiostreamerscrobbler.players.musiccast.{MusicCastPlayer, MusicCastDeviceDescriptorXmlParser}
import audiostreamerscrobbler.players.protocols.SSDPHandler

import java.net.URL

let SEARCH_TEXT_MUSICCAST = "urn:schemas-upnp-org:device:MediaRenderer:1"
let DEBUG = false

function createMusicCastDetector = |cb| {
	let ssdpHandler = getSsdpHandlerInstance()
	let hosts = set[]
	let ssdpCb = createSsdpCallback(ssdpHandler, hosts, cb)

	let detector = DynamicObject("MusicCastDetector"):
		define("_ssdpHandler", |this| -> ssdpHandler):
		define("_ssdpCb", |this| -> ssdpCb):
		define("_hosts", hosts):
		define("playerType", PlayerTypes.MusicCast()):
		define("start", |this| -> startMusicCastDetector(this)):
		define("stop", |this| -> stopMusicCastDetector(this))
		
	return detector
}

local function createSsdpCallback = |ssdpHandler, hosts, cb| {
	let parser = createMusicCastDeviceDescriptorParser()
	
	let ssdpCb = |host, headers| {
		if (host isnt null and hosts: contains(host)) {
			if (DEBUG) {
				println("Device at '" + host + "' is already known")
			}
			return
		}
		hosts: add(host)

		let deviceDescriptorUrl = headers: get("location")
		if (deviceDescriptorUrl is null) {
			if (DEBUG) {
				println("No Device Descriptor URL found in HTML header. This is not a supported MusicCast device.")
			}
			return
		}
		var inputStream = null
		try {
			inputStream = URL(deviceDescriptorUrl): openStream()

			let deviceDescriptor = parser: parse(inputStream)

			if (not _isMusicCastDevice(deviceDescriptor)) {
				if (DEBUG) {
					println("Device could not be validated as valid MusicCast device")
				}
				return
			}

			let musicCastImpl = _createMusicCastImpl(deviceDescriptor)
			let musicCastPlayer = createMusicCastPlayer(musicCastImpl)
			cb(musicCastPlayer)
		} catch(ex) {
			# Devices that fail should never be ignored. It can be caused temporary I/O
			# errors, or bugs in the program.
			if (host isnt null) {
				hosts: remove(host)
			}
			throw(ex)
		} finally {
			if (inputStream != null) {
				inputStream: close()
			}
		}
	}
	return ssdpCb
}

local function startMusicCastDetector = |detector| {
	detector: _hosts(): clear()
	
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
