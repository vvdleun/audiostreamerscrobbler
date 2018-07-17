module audiostreamerscrobbler.players.protocols.SSDPHandler

import audiostreamerscrobbler.factories.SocketFactory
import audiostreamerscrobbler.utils.{NetworkUtils, ThreadUtils}

import gololang.concurrent.workers.WorkerEnvironment
import java.io.IOException
import java.lang.Thread
import java.net.{DatagramPacket, InetAddress, SocketTimeoutException}
import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}

let MULTICAST_ADDRESS_IP4 = "239.255.255.250"
let MULTICAST_ADDRESS_IP6 = "FF05::C"
let MULTICAST_UDP_PORT = 1900
let BUFFER_SIZE = 4 * 1024
let SSDP_SECS = 1
let IO_ERROR_SLEEP_TIME = 10

let ssdpHandler = createSsdpHandler()

function getSsdpHandlerInstance = -> ssdpHandler

union SsdpHandlerMsgs = {
	AddCallbackMsg = { searchText, cb }
	RemoveCallbackMsg = { searchText, cb }
	ExecuteMSearchQueriesMsg
	ExecuteCallbacksMsg = { values }
	ShutdownMsg
}

local function createSsdpHandler = {
	let ssdpHandler = DynamicObject("SSDPHandler"):
		define("_env", null):
		define("_port", null):
		define("_multicastAddress", null):
		define("_threadSender", null):
		define("_threadReceiver", null):
		define("_socketMSearch", null):
		define("_isRunning", null):
		define("_callbacks", null):
		define("shutdown", |this| -> shutdownSsdpHandler(this)):
		define("addCallback", |this, searchText, cb| -> scheduleAddCallback(this, searchText, cb)):
		define("removeCallback", |this, searchText, cb| -> scheduleRemoveCallback(this, searchText, cb))
 	
	initAndStartSsdpHandler(ssdpHandler)
	
	return ssdpHandler
}

local function initAndStartSsdpHandler = |handler| {
	if (handler: _env() isnt null) {
		raise("Internal error: player control thread was already running")
	}

	let env = WorkerEnvironment.builder(): withSingleThreadExecutor() 
	let port = env: spawn(^_portIncomingMsgHandler: bindTo(handler))

	handler: _env(env)
	handler: _port(port)
	handler: _callbacks(map[])
	handler: _isRunning(AtomicReference(AtomicBoolean(false)))

	# Sender / Receiver threads will be created once callbacks are added
	handler: _threadSender(null)
	handler: _threadReceiver(null)
}

local function shutdownSsdpHandler = |handler| {
	handler: _isRunning(): get(): set(false)
	handler: _port(): send(SsdpHandlerMsgs.ShutdownMsg())
}

local function scheduleAddCallback = |handler, searchText, cb| {
	if (handler: _port() is null) {
		raise("Internal error: SSDP handler thread is not started")
	}
	handler: _port(): send(SsdpHandlerMsgs.AddCallbackMsg(searchText, cb))
}

local function scheduleRemoveCallback = |handler, searchText, cb| {
	# println("*** Scheduling removal of callback...")
	if (handler: _port() is null) {
		raise("Internal error: SSDP handler thread is not started")
	}

	handler: _port(): send(SsdpHandlerMsgs.RemoveCallbackMsg(searchText, cb))
}

# Port message handler

local function _portIncomingMsgHandler = |handler, msg| {
	case {
		when msg: isAddCallbackMsg() {
			_addCallbackAndStartWhenAddedFirstCallback(handler, msg)
		}
		when msg: isRemoveCallbackMsg() {
			_removeCallbackAndStopWhenLastItemRemoved(handler, msg)
		}
		when msg: isExecuteMSearchQueriesMsg() {
			_executeMSearchQueries(handler)
		}
		when msg: isExecuteCallbacksMsg() {
			_executeCallbacks(handler, msg)
		}
		when msg: isShutdownMsg() {
			_shutdown(handler)
		}
		otherwise {
			raise("Internal error, received unknown message: " + msg)
		}
	}
}

# Functions that should be called via _portIncomingMsgHandler (direct or indirectly) only

local function _addCallbackAndStartWhenAddedFirstCallback = |handler, msg| {
	let callbacks = handler: _callbacks()
	let st = msg: searchText()
	var init = false
	
	if (not callbacks: containsKey(st)) {
		callbacks: put(st, list[])
		init = true
	}
	
	let stCallbacks = callbacks: get(st)
	let cb = msg: cb()
	stCallbacks: add(cb)
	
	if (init and callbacks: size() == 1) {
		_startSdpSearchHandler(handler)
	}
}

local function _startSdpSearchHandler = |handler| {
	let isRunning = -> handler: _isRunning(): get()
	isRunning(): set(true)

	_createSsdpInitThread(handler)
}

local function _createSsdpInitThread = |handler| {
	println("Initializing SSDP handler...")

	return runInNewThread("SsdpInitThread", {
		let isRunning = -> handler: _isRunning(): get()
		var isInitialized = false

		while (isRunning(): get() and not isInitialized) {
			try {
				let multicastAddress = InetAddress.getByName(MULTICAST_ADDRESS_IP4)

				# TODO Usually objects do not import factories, but what to do with this singleton?!
				let socketFactory = createSocketFactory()
				
				let socketMSearch = socketFactory: createMulticastSocket()
				socketMSearch: setSoTimeout(10 * 1000)

				handler: _multicastAddress(multicastAddress)
				handler: _socketMSearch(socketMSearch)

				isInitialized = true
			} catch(ex) {
				case {
					when ex oftype IOException.class {
						println("I/O error occurred, cannot initialize SSDP handler: '" + ex + "'. Will try again in " + IO_ERROR_SLEEP_TIME + " seconds.")
					}
					otherwise {
						raise("Unknown occurred, cannot initialize SSDP handler")
					}
				}
				Thread.sleep(IO_ERROR_SLEEP_TIME * 1000_L)
				continue
			}
		}

		# Let's make sure threads cannot be created endlessly in a loop
		let threadSender = _createAndRunSendThread(handler)
		let threadReceiver = _createAndRunReceiveThread(handler)
		handler: _threadSender(threadSender)
		handler: _threadReceiver(threadReceiver)
		println("SSDP I/O handler threads are running. Initialization of SSDP handler is done.")
	})
	
}

local function _createAndRunSendThread = |handler| {
	println("Starting SSDP discovery thread...")
	
	return runInNewThread("SsdpSenderThread", {
		let isRunning = -> handler: _isRunning(): get()

		while (isRunning(): get()) {
			handler: _port(): send(SsdpHandlerMsgs.ExecuteMSearchQueriesMsg())
			Thread.sleep(10000_L)
		}
		println("Stopping SSDP discovery thread...")
	})
}

local function _createAndRunReceiveThread = |handler| {
	println("Starting SSDP traffic handler thread...")

	return runInNewThread("SsdpReceiverThread", {
		let isRunning = -> handler: _isRunning(): get()

		while(isRunning(): get()) {
			let buffer = newTypedArray(byte.class, BUFFER_SIZE)
			let recv = DatagramPacket(buffer, buffer: length())
			try {
				# println("MSEARCH THREAD: Waiting for data...")
				let socketMSearch = handler: _socketMSearch()
				socketMSearch: receive(recv)
			} catch (ex) {
				case {
					when ex oftype SocketTimeoutException.class {
						# println(ex)
						# println("SSDP timeout")
						continue
					}
					when ex oftype IOException.class {
						println("I/O Error occurred while sending SSDP search query: " + ex + ". Staying idle for " + IO_ERROR_SLEEP_TIME + " seconds...")
						Thread.sleep(IO_ERROR_SLEEP_TIME * 1000_L)
						continue
					}
					otherwise {
						println("SSDP error: " + ex)
						throw ex
					}
				}
			}
			let incomingMsg = String(buffer, "UTF-8")
			let status, headers = _getValues(incomingMsg)

			if (status: size() > 1 and status: get(1) == "200") {
				handler: _port(): send(SsdpHandlerMsgs.ExecuteCallbacksMsg(headers))
			}
		}
		println("Stopping SSDP traffic handler thread...")
	})
}

local function _getValues = |msg| {
	let splitMsg = msg: trim(): split("\r\n"): asList()
	let header, headerLines... = splitMsg
	let mapHeader = map[]
	foreach headerLine in headerLines {
		if (headerLine == null) {
			break
		}

		let keyValue = headerLine: split(": ", 2)
		let key = keyValue: get(0): toLowerCase()
		let value = match {
			when keyValue: length() > 1 then keyValue: get(1)
			otherwise null
		}
		
		mapHeader: put(key, value)
	}
	return [header: split(" ", 3): asList(), mapHeader]
}

local function _removeCallbackAndStopWhenLastItemRemoved = |handler, msg| {
	let callbacks = handler: _callbacks()
	let st = msg: searchText()
	let cb = msg: cb()

	let stCallbacks = callbacks: get(st)

	stCallbacks: remove(cb)

	if (stCallbacks: size() == 0) {
		callbacks: remove(st)
	}
		
	if (callbacks: size() == 0) {
		_stopSdpSearchHandler(handler)
	}
}

local function _stopSdpSearchHandler = |handler| {
	handler: _isRunning(): get(): set(false)
}

local function _executeMSearchQueries = |handler| {
	handler: _callbacks(): keySet(): each(|st| {
		let isRunning = -> handler: _isRunning(): get()

		foreach (i in range(3)) {
			if (not isRunning(): get()) {
				break
			}
			sendMSearchQuery(handler, st, SSDP_SECS)
			Thread.sleep(1000_L)
		}
	})
}

local function sendMSearchQuery = |handler, searchText, seconds| {
	# println("Sending MSearch query... ")
	let msg = createMSearchString(MULTICAST_ADDRESS_IP4, MULTICAST_UDP_PORT, searchText, seconds)
	# println("'" + msg + "'")
	let msgBytes = msg: getBytes("UTF-8")
	let multicastAddress = handler: _multicastAddress()
	let mSearchPacket = DatagramPacket(msgBytes, msgBytes: length(), multicastAddress, MULTICAST_UDP_PORT)
	
	let socketMSearch = handler: _socketMSearch()
	socketMSearch: send(mSearchPacket)
}

local function createMSearchString = |multicastAddress, multicastPort, searchTarget, seconds| {
	let msg = StringBuilder()

	msg: append("M-SEARCH * HTTP/1.1\r\n")
	msg: append("Host: ")
	msg: append(multicastAddress)
	msg: append(":")
	msg: append(multicastPort: toString())
	msg: append("\r\n")
	msg: append("ST: ")
	msg: append(searchTarget)
	msg: append("\r\n")
	msg: append("Man: \"ssdp:discover\"\r\n")
	msg: append("MX: ")
	msg: append(seconds: toString())
	msg: append("\r\n")
	msg: append("\r\n")

	return msg: toString()
}

local function _executeCallbacks = |handler, msg| {
	handler: _callbacks(): entrySet(): each(|e| {
		let st = e: getKey()
		let stCallbacks = e: getValue()
		let v = msg: values()
		if (st == null) or (v: containsKey("st") and v: getOrElse("st", "") == st) {
			stCallbacks: each(|cb| -> cb(v))
		}
	})
}

local function _shutdown = |handler| {
	println("SSDP handler shutting down...")
	handler: _env(): shutdown()
	handler: _env(null)
	handler: _port(null)
}
