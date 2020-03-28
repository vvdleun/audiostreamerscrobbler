module audiostreamerscrobbler.players.heos.HeosDetector

import audiostreamerscrobbler.maintypes.Player.types.PlayerTypes
import audiostreamerscrobbler.players.heos.{HeosConnectionSingleton, HeosDeviceDescriptorXmlParser, HeosPlayer}
import audiostreamerscrobbler.players.heos.HeosPlayer.types.HeosImpl
import audiostreamerscrobbler.players.protocols.SSDPHandler
import audiostreamerscrobbler.utils.ThreadUtils

import java.lang.Thread
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

let DEBUG = false
let SEARCH_TEXT_HEOS = "urn:schemas-denon-com:device:ACT-Denon:1"
let PORT_HEOS = 1255
let REQUEST_PLAYERS_INTERVAL = 60
let CMD_GET_PLAYERS = "player/get_players"
let CMD_ENABLE_CHANGE_EVENTS = "system/register_for_change_events"

union HeosDetectModes = {
	FindPlayerMode
	ConnectedMode
}

function createHeosDetector = |cb| {
	let heosConnection = getHeosConnectionInstance()
	let ssdpHandler = getSsdpHandlerInstance()
	let isRunning = AtomicBoolean(false)

	let detector = DynamicObject("HeosDetector"):
		define("_cb", |this| -> cb):
		define("_heosConnection", |this| -> heosConnection):
		define("_ssdpHandler", |this| -> ssdpHandler):
		define("_isRunning", isRunning):
		define("playerType", PlayerTypes.Heos()):
		define("start", |this| -> startHeosDetector(this)):
		define("stop", |this| -> stopHeosDetector(this))

	let ignoredHosts = set[]
	let ssdpCb = _createSsdpCallback(detector, ignoredHosts)

	detector: define("_ssdpCb", |this| -> ssdpCb)

	let heosCb = _createHeosCallback(detector)

	detector: define("_heosCb", |this| -> heosCb)

	return detector
}

local function startHeosDetector = |detector| {
	let isRunning = detector: _isRunning()
	isRunning: set(true)	

	let mode = _getMode(detector)
	case {
		when mode: isFindPlayerMode() {
			_startFindingPlayerMode(detector)
		}
		when mode: isConnectedMode() {
			_startConnectedMode(detector)
		}
		otherwise {
			raise("Internal error, unknown mode: " + mode)
		}
	}
}

local function stopHeosDetector = |detector| {
	let isRunning = detector: _isRunning()
	isRunning: set(false)

	_stopFindingPlayerMode(detector)
	_stopConnectedMode(detector)
}

local function _getMode = |detector| {
	if (detector: _heosConnection(): isConnected()) {
		return HeosDetectModes.ConnectedMode()
	}
	return HeosDetectModes.FindPlayerMode()
}

# FindPlayerMode handling (Find a HEOS player to connect to)

local function _startFindingPlayerMode = |detector| {
	let ssdpHandler = detector: _ssdpHandler()
	ssdpHandler: addCallback(SEARCH_TEXT_HEOS, detector: _ssdpCb())

	println("Looking for HEOS player to connect to...")
}

local function _stopFindingPlayerMode = |detector| {
	let ssdpHandler = detector: _ssdpHandler()
	ssdpHandler: removeCallback(SEARCH_TEXT_HEOS, detector: _ssdpCb())
}

local function _createSsdpCallback = |detector, ignoredHosts| {
	let parser = createHeosDeviceDescriptorXMLParser()

	let ssdpCb = |host, headers| {
		if (host isnt null and ignoredHosts: contains(host)) {
			if (DEBUG) {
				println("Device at '" + host + "' is ignored")
			}
			return
		} else if (detector: _heosConnection(): isConnected()) {
			if (DEBUG) {
				println("Already connected to HEOS player")
			}
			return
		} else if (not detector: _isRunning(): get()) {
			if (DEBUG) {
				println("HEOS detector is stopped")
			}
			return
		}

		var inputStream = null
		try { 
			let deviceDescriptorUrl = headers: get("location")
			if (deviceDescriptorUrl isnt null) {
				inputStream = URL(deviceDescriptorUrl): openStream()
				try {
					let deviceDescriptor = parser: parse(inputStream)
					if (_isHeosDevice(deviceDescriptor)) {
						let heosConnection = detector: _heosConnection()
						let deviceDescriptorHost = _getHost(deviceDescriptorUrl)

						heosConnection: connect(deviceDescriptorHost, PORT_HEOS)

						_stopFindingPlayerMode(detector)
						_startConnectedMode(detector)
					} else {
						# Always ignore unknown hosts
						ignoredHosts: add(host)
					}
				} finally {
					inputStream: close()
				}
			}
		} catch(ex) {
			println("Error while processing incoming possible HEOS SSDP data: " + ex)
			throw(ex)
		} finally {
			if (inputStream != null) {
				inputStream: close()
			}
		}
	}
	return ssdpCb
}

local function _isHeosDevice = |deviceDescriptor| {
	# Denon does not document how to verify that device is a true HEOS compatible
	# product. So this validation should be considered an uneducated guess.
	return (deviceDescriptor: deviceType() == "urn:schemas-denon-com:device:AiosDevice:1")
}

local function _getHost = |url| {
	var result = url

	let protocolIndex = result: indexOf("://")
	if (protocolIndex >= 0) {
		result = result: substring(protocolIndex + 3)
	}

	let portIndex = result: indexOf(":")
	if (portIndex >= 0) {
		result = result: substring(0, portIndex)
	}

	let pathIndex = result: indexOf("/")
	if (pathIndex >= 0) {
		result = result: substring(0, pathIndex)
	}

	return result
}

# ConnectedMode handling (Send commands to HEOS player to find other players in the network)

local function _startConnectedMode = |detector| {
	let heosConnection = detector: _heosConnection()

	let host = heosConnection: host()
	println("Connected to HEOS player's CLI server at " + host + ".")

	heosConnection: addCallback(detector: _heosCb())

	let thread = _createAndRunFindPlayersThread(detector)

	# TODO 1: this command should not be given more than once...
	# TODO 2: Ensure this command was processed correctly
	heosConnection: sendCommand("heos://" + CMD_ENABLE_CHANGE_EVENTS + "?enable=on")
}

local function _stopConnectedMode = |detector| {
	let heosConnection = detector: _heosConnection()
	heosConnection: removeCallback(detector: _heosCb())
}

local function _createAndRunFindPlayersThread = |detector| {
	if (DEBUG) {
		println("Starting HeosAliveThread...")
	}
	return runInNewThread("HeosAliveThread", {
		let heosConnection = detector: _heosConnection()
		let isRunning = detector: _isRunning()

		while (isRunning: get()) {
			if(not heosConnection: isConnected()) {
				println("Lost connection to HEOS player")
				_stopConnectedMode(detector)
				_startFindingPlayerMode(detector)
				return
			}

			heosConnection: sendCommand("heos://" + CMD_GET_PLAYERS)

			Thread.sleep(REQUEST_PLAYERS_INTERVAL * 1000_L)
		}

		if (DEBUG) {
			println("Stopping HeosAliveThread...")
		}
	})
}

local function _createHeosCallback = |detector| {
	let heosCb = |response| {
		let cb = detector: _cb()
		let heos = response: get("heos")

		if (heos: get("command") == CMD_GET_PLAYERS) {
			if (heos: get("result") != "success") {
				println("ERROR RESPONSE FROM HEOS: " + response)
				return
			}

			let players = response: get("payload")

			foreach (player in players) {
				let heosPlayerImpl = HeosImpl(
						player: get("pid"),
						player: get("name"),
						player: get("model"),
						player: get("ip"))

				let heosPlayer = createHeosPlayer(heosPlayerImpl)
				cb(heosPlayer)
			}
		}
	}
	return heosCb
}
