module audiostreamerscrobbler.players.protocols.SSDPHandler

import audiostreamerscrobbler.factories.SocketFactory
import audiostreamerscrobbler.players.protocols.SSDPHandlerCallbackResultTypes.types.SSDPHandlerCallbackResult
import audiostreamerscrobbler.utils.{NetworkUtils, ThreadUtils}

import gololang.concurrent.workers.WorkerEnvironment
import java.io.IOException
import java.lang.Thread
import java.net.{DatagramPacket, InetAddress, SocketTimeoutException}
import java.util.concurrent.atomic.AtomicBoolean

let MULTICAST_ADDRESS_IP4 = "239.255.255.250"
let MULTICAST_ADDRESS_IP6 = "FF05::C"
let MULTICAST_UDP_PORT = 1900
let BUFFER_SIZE = 4 * 1024
let SSDP_SECS = 1
let IO_ERROR_SLEEP_TIME = 10
let THREAD_SENDER_NAME = "SsdpOutputThread"
let THREAD_RECEIVER_NAME = "SsdpInputThread"

let ssdpHandler = createSsdpHandler()

function getSsdpHandlerInstance = -> ssdpHandler

union SsdpHandlerMsgs = {
	AddCallbackMsg = { searchText, cb }
	RemoveCallbackMsg = { searchText, cb }
	ExecuteMSearchQueriesMsg
	ExecuteCallbacksMsg = { values }
	ThreadFinishedMsg = { name }
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
		define("_finishedThreads", null):
		define("shutdown", |this| -> shutdownSsdpHandler(this)):
		define("addCallback", |this, searchText, cb| -> scheduleAddCallback(this, searchText, cb)):
		define("removeCallback", |this, searchText, cb| -> scheduleRemoveCallback(this, searchText, cb))
 	
	_initAndStartSsdpHandler(ssdpHandler)
	
	return ssdpHandler
}

local function _initAndStartSsdpHandler = |handler| {
	if (handler: _env() isnt null) {
		raise("Internal error: player control thread was already running")
	}

	let env = WorkerEnvironment.builder(): withSingleThreadExecutor() 
	let port = env: spawn(^_portIncomingMsgHandler: bindTo(handler))

	handler: _env(env)
	handler: _port(port)
	handler: _callbacks(map[])
	handler: _isRunning(AtomicBoolean(false))

	# Sender / Receiver threads will be created once callbacks are added
	handler: _threadSender(null)
	handler: _threadReceiver(null)
	
}

local function shutdownSsdpHandler = |handler| {
	handler: _isRunning(): set(false)
	handler: _port(): send(SsdpHandlerMsgs.ShutdownMsg())
}

local function scheduleAddCallback = |handler, searchText, cb| {
	if (handler: _port() is null) {
		raise("Internal error: SSDP handler thread is not started")
	}
	handler: _port(): send(SsdpHandlerMsgs.AddCallbackMsg(searchText, cb))
}

local function scheduleRemoveCallback = |handler, searchText, cb| {
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
		when msg: isThreadFinishedMsg() {
			_closeSocketIfAllThreadsFinished(handler, msg)
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
	handler: _isRunning(): set(true)

	_createSsdpInitThread(handler)
}

local function _createSsdpInitThread = |handler| {
	println("Initializing SSDP handler...")

	return runInNewThread("SsdpInitThread", {
		var isInitialized = false

		handler: _finishedThreads(map[])

		while (handler: _isRunning(): get() and not isInitialized) {
			var socketMSearch = null
			try {
				let multicastAddress = InetAddress.getByName(MULTICAST_ADDRESS_IP4)

				# TODO Usually objects do not import factories, but what to do with this singleton?!
				let socketFactory = createSocketFactory()
				
				socketMSearch = socketFactory: createMulticastSocket()
				socketMSearch: setSoTimeout(10 * 1000)

				handler: _multicastAddress(multicastAddress)
				handler: _socketMSearch(socketMSearch)

				isInitialized = true
			} catch(ex) {
				if (socketMSearch isnt null) {
					socketMSearch: close()
				}
				case {
					when ex oftype IOException.class {
						println("I/O error while initializing SSDP network sockets: '" + ex + "'. Will try again in " + IO_ERROR_SLEEP_TIME + " seconds.")
					}
					otherwise {
						raise("Unknown exception was thrown, cannot initialize SSDP handler")
					}
				}
				Thread.sleep(IO_ERROR_SLEEP_TIME * 1000_L)
				continue
			}
		}

		# Let's make sure new threads are not created inside a loop
		if (isInitialized) {
			let threadSender = _createAndRunSendThread(handler)
			let threadReceiver = _createAndRunReceiveThread(handler)
			handler: _threadSender(threadSender)
			handler: _threadReceiver(threadReceiver)
			println("SSDP I/O handler threads are running. Initialization of SSDP handler is done.")
		}
	})
}

local function _createAndRunSendThread = |handler| {
	println("Starting SSDP network output handler thread...")
	
	return runInNewThread(THREAD_SENDER_NAME, {
		while (handler: _isRunning(): get()) {
			handler: _port(): send(SsdpHandlerMsgs.ExecuteMSearchQueriesMsg())
			Thread.sleep(30000_L)
		}
		println("Stopping SSDP network output handler thread...")
		handler: _port(): send(SsdpHandlerMsgs.ThreadFinishedMsg(THREAD_SENDER_NAME))

	})
}

local function _createAndRunReceiveThread = |handler| {
	println("Starting SSDP network input handler thread...")

	return runInNewThread(THREAD_RECEIVER_NAME, {
		let buffer = newTypedArray(byte.class, BUFFER_SIZE)
		let datagramPacket = DatagramPacket(buffer, buffer: length())
		let socketMSearch = handler: _socketMSearch()

		while(handler: _isRunning(): get()) {
			try {
				# println("MSEARCH THREAD: Waiting for data...")
				socketMSearch: receive(datagramPacket)
			} catch (ex) {
				case {
					when ex oftype SocketTimeoutException.class {
						# println(ex)
						# println("SSDP timeout")
						continue
					}
					when ex oftype IOException.class {
						println("I/O error while sending SSDP search query: '" + ex + "'. Will try again in " + IO_ERROR_SLEEP_TIME + " seconds.")
						Thread.sleep(IO_ERROR_SLEEP_TIME * 1000_L)
						continue
					}
					otherwise {
						println("SSDP error: " + ex)
						throw ex
					}
				}
			}
			let incomingMsg = String(datagramPacket: getData(), 0, datagramPacket: getLength() , "UTF-8")
			let status, headers = _getValues(incomingMsg)

			if (status: size() > 1 and status: get(1) == "200") {
				handler: _port(): send(SsdpHandlerMsgs.ExecuteCallbacksMsg(headers))
			}
		}
		println("Stopping SSDP network input handler thread...")
		handler: _port(): send(SsdpHandlerMsgs.ThreadFinishedMsg(THREAD_RECEIVER_NAME))
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
	if (stCallbacks is null) {
		return
	}
	
	stCallbacks: remove(cb)
	
	if (stCallbacks: size() == 0) {
		callbacks: remove(st)
	}
		
	if (callbacks: size() == 0) {
		_stopSdpSearchHandler(handler)
	}
}

local function _stopSdpSearchHandler = |handler| {
	handler: _isRunning(): set(false)
}

local function _executeMSearchQueries = |handler| {
	handler: _callbacks(): keySet(): each(|st| {
		foreach (i in range(3)) {
			if (not handler: _isRunning(): get()) {
				return
			}
			try {
				sendMSearchQuery(handler, st, SSDP_SECS)
			} catch(ex) {
				println("Error while sending outgoing SSDP data: " + ex)
			}
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
		let headerValues = msg: values()
		let host = headerValues: getOrElse("host", headerValues: get("location"))
		let matchesSearchText = headerValues: containsKey("st") and headerValues: getOrElse("st", "") == st
		if (st == null or matchesSearchText) {
			stCallbacks: each(|cb| {
				try {
					cb(host, headerValues)
				} catch(ex) {
					case {
						when ex oftype IOException.class {
							println("I/O error while handling incoming SSDP data: " + ex)
						}
						otherwise {
							println("Unknown error while handling incoming SSDP data: " + ex)
							throw ex
						}
					}
				}
			})
		}
	})
}

local function _closeSocketIfAllThreadsFinished = |handler, msg| {
	let threadName = msg: name()
	let finishedThreads = handler: _finishedThreads()
	finishedThreads: put(threadName, true)
	let reveiverThreadFinished = finishedThreads: getOrElse(THREAD_RECEIVER_NAME, false)
	let senderThreadFinished = finishedThreads: getOrElse(THREAD_SENDER_NAME, false)
	if (reveiverThreadFinished and senderThreadFinished) {
		println("Closing SSDP socket ")
		handler: _socketMSearch(): close()
	}
}

local function _shutdown = |handler| {
	println("SSDP handler shutting down...")
	handler: _env(): shutdown()
	handler: _env(null)
	handler: _port(null)
}
