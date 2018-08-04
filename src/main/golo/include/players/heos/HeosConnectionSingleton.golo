module audiostreamerscrobbler.players.heos.HeosConnectionSingleton

import audiostreamerscrobbler.factories.SocketFactory
import audiostreamerscrobbler.players.heos.{HeosDeviceDescriptorXmlParser, HeosPlayer}
import audiostreamerscrobbler.players.protocols.SSDPHandler
import audiostreamerscrobbler.utils.ThreadUtils

import gololang.concurrent.workers.WorkerEnvironment
import java.io.{BufferedReader, IOException, InputStreamReader, OutputStreamWriter, PrintWriter}
import java.net.{Socket, URL}
import java.time.{Duration, Instant}
import java.util.concurrent.atomic.{AtomicBoolean, AtomicInteger}

let DEBUG = false
let SEARCH_TEXT_HEOS = "urn:schemas-denon-com:device:ACT-Denon:1"
let PORT_HEOS = 1255
let MAX_CALLBACKS = 100
let MAX_TIMEOUTS = 3
let IGNORE_FAILED_DEVICE_SECONDS = 20
let TIMEOUT_SECONDS = 120

union HeosModes = {
	IdleMode
	FindPlayerMode
	ConnectedMode
}

union HeosConnectionMsgs = {
	StartMsg
	FindPlayerMsg
	ConnectToPlayerMsg = { host, port, name }
	SendCommandMsg = { cmd, cb, autoRemoveCb }
	RemoveCallbackMsg = { cmd, cb }
	StopMsg
}

let heosConnection = createHeosConnection()

function getHeosConnectionInstance = -> heosConnection

local function createHeosConnection = {
	let heosConnection = DynamicObject("HEOSConnection"):
		define("_env", null):
		define("_port", null):
		define("_ssdpCb", null):
		define("_ssdpHandler", |this| -> getSsdpHandlerInstance()):
		define("_mode", HeosModes.IdleMode()): 
		define("_failingPlayers", null):
		define("_callbacks", null):
		define("_socket", null):
		define("_printWriter", null):
		define("_inputStreamReader", null):
		define("_socketFactory", |this| -> createSocketFactory()):
		define("_isOpened", AtomicBoolean(false)):
		define("_connectionId", AtomicInteger(0)):
		define("isOpened", |this| -> this: _isOpened(): get()):
		define("sendCommand", |this, cmd, cb| -> sendCommand(this, cmd, cb)):
		define("removeCallback", |this, cmd, cb| -> removeCallback(this, cb)):
		define("open", |this| -> startHeosConnectionHandler(this)):
		define("close", |this| -> stopHeosConnectionHandler(this))

	_initHeosConnectionHandler(heosConnection)
		
	return heosConnection
}

local function _initHeosConnectionHandler = |connection| {
	println("Initializing HEOS connection thread...")

	let env = WorkerEnvironment.builder(): withSingleThreadExecutor() 
	let port = env: spawn(^_portIncomingMsgHandler: bindTo(connection))
	let ssdpCb = _createSsdpCallback(connection)
	let failingPlayers = map[]
	let callbacks = map[]
	
	connection: _env(env)
	connection: _port(port)
	connection: _ssdpCb(|this| -> ssdpCb)
	connection: _failingPlayers(failingPlayers)
	connection: _callbacks(callbacks)
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

local function startHeosConnectionHandler = |connection| {
	connection: _port(): send(HeosConnectionMsgs.StartMsg())
}

local function stopHeosConnectionHandler = |connection| {
	connection: _port(): send(HeosConnectionMsgs.StopMsg())
}

local function sendCommand = |connection, cmd, cb| {
	connection: _port(): send(HeosConnectionMsgs.SendCommandMsg(cmd, cb, true))
}

local function removeCallback = |connection, cmd, cb| {
	connection: _port(): send(HeosConnectionMsgs.RemoveCallbackMsg(cmd, cb))
}

# Port message handler

local function _portIncomingMsgHandler = |connection, msg| {
	case {
		when msg: isStartMsg() {
			_handleStartMsg(connection)
		}
		when msg: isFindPlayerMsg() {
			_handleFindPlayerMsg(connection)
		}
		when msg: isConnectToPlayerMsg() {
			_handleConnectToPlayerMsg(connection, msg: host(), msg: port(), msg: name())
		}
		when msg: isSendCommandMsg() {
			_handleSendCommandMsg(connection, msg: cmd(), msg: cb())
		}
		when msg: isStopMsg() {
			_handleStopMsg(connection)
		}
		otherwise {
			raise("Internal error, received unknown message: " + msg)
		}
	}
}

# Functions that should be called via _portIncomingMsgHandler (direct or indirectly) only

local function _handleStartMsg = |connection| {
	if (not connection: _mode(): isIdleMode()) {
		println("Internal error: HEOS connection handler is not idle")
	}
	connection: _isOpened(): set(true)
	_handleFindPlayerMsg(connection)
}

local function _handleFindPlayerMsg = |connection| {
	if (connection: _mode(): isFindPlayerMode()) {
		if (DEBUG) {
			println("HeosConnectionHandler is already in Find Player Mode")
		}
		return
	}
	connection: _mode(HeosModes.FindPlayerMode())
	_startSdpDetector(connection)

}

local function _startSdpDetector = |connection| {
	let ssdpHandler = connection: _ssdpHandler()
	let ssdpCb = connection: _ssdpCb()
	ssdpHandler: addCallback(SEARCH_TEXT_HEOS, ssdpCb)
}
 
local function _createSsdpCallback = |connection| {
	let ssdpCb = |headers| {
		try {
			let deviceDescriptorUrl = headers: get("location")
			if (deviceDescriptorUrl isnt null) {
				let inputStream = URL(deviceDescriptorUrl): openStream()
				try {
					let deviceDescriptor = parseHeosDeviceDescriptorXML(inputStream)
					if (_isHeosDevice(deviceDescriptor)) {
						let host = _getHost(deviceDescriptorUrl)
						let name = deviceDescriptor: name()
						connection: _port(): send(HeosConnectionMsgs.ConnectToPlayerMsg(host, PORT_HEOS, name))
					}
				} finally {
					inputStream: close()
				}
			}
		} catch(ex) {
			println("Error while processing incoming possible HEOS SSDP data: " + ex)
		}
	}
	return ssdpCb
}

local function _stopSdpDetector = |connection| {
	let ssdpHandler = connection: _ssdpHandler()
	ssdpHandler: removeCallback(SEARCH_TEXT_HEOS, connection: _ssdpCb())
}

local function _handleConnectToPlayerMsg = |connection, host, port, name| {
	if (not connection: _mode(): isFindPlayerMode()) {
		return
	} else if _hasDeviceFailedToConnectRecently(connection, name) {
		println("No connection could be established with HEOS player '" + name + "' recently. This device is ignored for a short time.")
		return
	}

	# Close current socket, if any
	let currentSocket = connection: _socket()
	if (currentSocket != null) {
		currentSocket: close()
	}
	
	# Determine connection ID. The receiver thread uses this to make sure that
	# socket was not changed since last exception. If it is, then it exits, knowing that
	# there should be a different thread handling the received input.
	let connectionId = connection: _connectionId(): getAndIncrement()
	connection: _connectionId(AtomicInteger(connectionId))

	println("Connecting to HEOS player '" + name + "' on '" + host + "', port '" + port + "' (connection ID #" + connectionId + ")")
	
	try {
		let socketFactory = connection: _socketFactory()

		let socket = socketFactory: createSocket(host, port)
		socket: setSoTimeout(TIMEOUT_SECONDS * 1000)

		let printWriter = PrintWriter(OutputStreamWriter(socket: getOutputStream(), "utf-8"), false)
		let inputStreamReader = BufferedReader(InputStreamReader(socket: getInputStream()))
		
		connection: _socket(socket)
		connection: _printWriter(printWriter)
		connection: _inputStreamReader(inputStreamReader)

		_stopSdpDetector(connection)
		
		if (name isnt null) {
			connection: _failingPlayers(): remove(name)
		}

		connection: _mode(HeosModes.ConnectedMode())

		# The response of the command(s) used to initialize the command are
		# ignored at this time
		_initConnection(connection)

		_createAndRunReceiveThread(connection, connectionId)
	} catch(ex) {
		# Mark player as failing and give it some time to breath.
		markPlayerAsFailing(connection, name)

		# Only I/O exceptions are acceptable
		case {
			when ex oftype IOException.class {
				println("I/O error while connecting to player: " + ex)
			}
			otherwise {
				throw(ex)
			}
		}
	}
}

local function markPlayerAsFailing = |connection, name| {
	if (name isnt null) {
		connection: _failingPlayers(): put(name, Instant.now())
	}
}

local function _createAndRunReceiveThread = |connection, connectionId| {
	println("Starting HEOS network input handler thread for connection id #" + connectionId + "...")
	return runInNewThread("HeosInputThread", {
		let reader = connection: _inputStreamReader()
		var timeouts = 0

		while (connectionId == connection: _connectionId(): get()) {
			println("HEOS waiting for data...")
			try {
				let line = reader: readLine()
				println(line)
			} catch(ex) {
				case {
					when ex oftype IOException.class {
						println("HEOS network input handler thread: I/O error occurred: " + ex)
						timeouts = timeouts + 1
						if (timeouts >= MAX_TIMEOUTS) {
							println("HEOS network input handler thread: too many timeouts.")
							if (connectionId == connection: _connectionId(): get()) {
								# This is not really thread safe. In worst case a perfectly
								# fine connection is aborted, if new connection was made
								# before connection ID was updated.
								# Let's see if this will cause problems in real life.
								println("HEOS connection handler is looking for player to connect to")
								_handleFindPlayerMsg(connection)
							}
							break
						}
					}
					otherwise {
						throw(ex)
					}
				}
			}
		}
		println("Stopping HEOS network input handler for connection id #" + connectionId + "...")
	})
}

local function _hasDeviceFailedToConnectRecently = |connection, name| {
	if (name is null or name == "") {
		# Devices without name cannot be verified at this time, unfortunately
		return false
	}
	let failedPlayers = connection: _failingPlayers()
	let timestamp = failedPlayers: get(name)
	if (timestamp is null) {
		# Device did not fail us. Yet.
		return false
	}
	let timeDiff = Duration.between(timestamp, Instant.now()): getSeconds()
	return (timestamp >= 0 and timestamp <= IGNORE_FAILED_DEVICE_SECONDS)
}

local function _initConnection = |connection| {
	let printWriter = connection: _printWriter()
	_sendCommand(printWriter, "heos://system/register_for_change_events?enable=off")
}

local function _handleSendCommandMsg = |connection, cmd, cb| {
	if (not connection: _mode(): isConnectedMode()) {
		# Simply ignore commands when not connected to any player
		if (DEBUG) {
			println("HEOSConnection is not connected to any player. Cannot send '" + cmd + "'")
		}
		return
	}
	
	let socket = connection: _socket()
	let printWriter = connection: _printWriter()
	
	try {
		_sendCommand(printWriter, cmd)
	} catch(ex) {
		# Only I/O exceptions are acceptable
		case {
			when ex oftype IOException.class {
				println("I/O error while sending command to player: " + ex)
				_handleFindPlayerMsg(connection)
			}
			otherwise {
				throw(ex)
			}
		}
		
	}
}

local function _sendCommand = |printWriter, cmd| {
	println("Sending command: '" + cmd + "'")
	printWriter: print(cmd + "\r\n")
	printWriter: flush()
}