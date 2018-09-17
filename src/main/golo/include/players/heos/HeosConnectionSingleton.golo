module audiostreamerscrobbler.players.heos.HeosConnectionSingleton

import audiostreamerscrobbler.factories.SocketFactory
import audiostreamerscrobbler.utils.ThreadUtils

import gololang.concurrent.workers.WorkerEnvironment
import java.io.{BufferedReader, IOException, InputStreamReader, OutputStreamWriter, PrintWriter}
import java.net.{Socket, URL}
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.CopyOnWriteArrayList

let DEBUG = false
let MAX_IO_ERRORS = 3
let TIMEOUT_SEC = 80
let SEND_COMMAND_MS = 250
let CMD_DISABLE_PRETTIFY_JSON = "heos://system/prettify_json_response?enable=off"
let CMD_DISABLE_CHANGE_EVENTS = "heos://system/register_for_change_events?enable=off"

union HeosConnectionMsgs = {
	SendCommandMsg = { cmd }
}

let heosConnection = createHeosConnection()

function getHeosConnectionInstance = -> heosConnection

local function createHeosConnection = {
	let isRunning = AtomicBoolean(false)
	let callbacks = CopyOnWriteArrayList()
	let socketFactory = createSocketFactory()
	
	let heosConnection = DynamicObject("HEOSConnection"):
		define("_callbacks", callbacks):
		define("_isRunning", isRunning):
		define("_socketFactory", |this| -> socketFactory):
		define("_socket", null):
		define("_printWriter", null):
		define("_inputStreamReader", null):
		define("_env", null):
		define("_port", null):
		define("playerHost", null):
		define("connect", |this, host, port| -> connect(this, host, port)):
		define("disconnect", |this| -> disconnect(this)):
		define("isConnected", |this| -> isConnected(this)):
		define("addCallback", |this, cb| -> addCallback(this, cb)):
		define("removeCallback", |this, cb| -> removeCallback(this, cb)):
		define("sendCommand", |this, cmd| -> sendCommand(this, cmd))

	return heosConnection
}

local function connect = |connection, host, port| {
	if (DEBUG) {
		println("Connecting to " + host + ":" + port + "...")
	}

	# Close current socket, if any
	if (connection: _socket() != null) {
		throw IOException("HEOSConnection is already connected")
	}

	let socketFactory = connection: _socketFactory()

	let socket = socketFactory: createSocket(host, port)
	socket: setSoTimeout(TIMEOUT_SEC * 1000)

	let outputStream = socket: getOutputStream()
	let printWriter = PrintWriter(OutputStreamWriter(outputStream, "utf-8"), false)

	let inputStream = socket: getInputStream()
	let inputStreamReader = BufferedReader(InputStreamReader(inputStream))

	let env = WorkerEnvironment.builder(): withSingleThreadExecutor() 
	let envPort = env: spawn(^_portIncomingMsgHandler: bindTo(connection))

	connection: _socket(socket)
	connection: _printWriter(printWriter)
	connection: _inputStreamReader(inputStreamReader)
	connection: _env(env)
	connection: _port(envPort)
	connection: playerHost(host + ":" + port)

	_initConnection(connection)

	_createAndRunReceiveThread(connection)

	if (DEBUG) {
		println("Connected to HEOS player.")
	}
}

local function _initConnection = |connection| {
	sendCommand(connection, CMD_DISABLE_PRETTIFY_JSON)
	sendCommand(connection, CMD_DISABLE_CHANGE_EVENTS)
}

local function disconnect = |connection| {
 	connection: _isRunning(): set(false)
}

local function isConnected = |connection| {
	return connection: _isRunning(): get() 
}

local function addCallback = |connection, cb| {
	connection: _callbacks(): add(cb)
}

local function removeCallback = |connection, cb| {
	connection: _callbacks(): remove(cb)
}

local function sendCommand = |connection, cmd| {
	connection: _port(): send(HeosConnectionMsgs.SendCommandMsg(cmd))
}

local function _createAndRunReceiveThread = |connection| {
	let isRunning = connection: _isRunning()
	isRunning: set(true)

	return runInNewThread("HeosConnectionInputThread", {
		let reader = connection: _inputStreamReader()
		var ioErrors = 0

		try {
			while (isRunning: get()) {
				if (DEBUG) {
					println("HEOS waiting for data...")
				}
				try {
					let textResponse = reader: readLine()
					if (DEBUG) {
						println("Incoming data: '" + textResponse + "'")
					}

					let jsonResponse = JSON.parse(textResponse)
					
					foreach (cb in connection: _callbacks()) {
						try {
							cb(jsonResponse)
						} catch(ex) {
							println("ERROR: " + ex)
							if (DEBUG) {
								throw(ex)
							}
						}
					}
				} catch(ex) {
					case {
						when ex oftype IOException.class {
							println("HEOS network input handler thread: I/O error occurred: " + ex)
							ioErrors = ioErrors + 1
							if (ioErrors >= MAX_IO_ERRORS) {
								println("HEOS network input handler thread: too many I/O errors.")
								isRunning: set(false)
							}
						}
						otherwise {
							println("Internal error while processing HEOS input: " + ex)
							if (DEBUG) {
								throw(ex)
							}
						}
					}
				}
			}
		} finally {
			if (DEBUG) {
				println("Stopping HEOS network connection")
			}
			isRunning: set(false)
			connection: _socket(): close()
			connection: _inputStreamReader(): close()
			connection: _printWriter(): close()

			connection: _socket(null)
			connection: _inputStreamReader(null)
			connection: _printWriter(null)

			connection: _env(): shutdown()
			connection: _env(null)
		}
	})
}

# Port message handler

local function _portIncomingMsgHandler = |connection, msg| {
	case {
		when msg: isSendCommandMsg() {
			_handleSendCommandMsg(connection, msg: cmd())
		}
		otherwise {
			raise("Internal error, received unknown message: " + msg)
		}
	}
}

# Functions that should be called via _portIncomingMsgHandler (direct or indirectly) only

local function _handleSendCommandMsg = |connection, cmd| {
	let socket = connection: _socket()
	let printWriter = connection: _printWriter()
	
	try {
		_sendCommand(printWriter, cmd)
	} catch(ex) {
		# Only I/O exceptions are acceptable
		case {
			when ex oftype IOException.class {
				println("I/O error while sending command to HEOS player: " + ex)
			}
			otherwise {
				throw(ex)
			}
		}
		
	}
}

local function _sendCommand = |printWriter, cmd| {
	if (DEBUG) {
		println("Sending command: '" + cmd + "'")
	}
	printWriter: print(cmd + "\r\n")
	printWriter: flush()

	Thread.sleep(SEND_COMMAND_MS * 1_L)
}