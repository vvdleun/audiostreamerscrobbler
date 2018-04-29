module audiostreamerscrobbler.players.protocols.SSDPHandler

import audiostreamerscrobbler.utils.ThreadUtils

import gololang.Observable
import java.lang.Thread
import java.net.{DatagramPacket, InetAddress,  MulticastSocket, SocketTimeoutException}
import java.util.concurrent.atomic.AtomicBoolean

let MULTICAST_ADDRESS_IP4 = "239.255.255.250"
let MULTICAST_ADDRESS_IP6 = "FF05::C"
let MULTICAST_UDP_PORT = 1900
let BUFFER_SIZE = 4 * 1024

let ssdpHandler = createSsdpHandler()

function getSsdpHandlerInstance = -> ssdpHandler

local function createSsdpHandler = {
	let observable = Observable("SSDPObservable")
	let isRunning = AtomicBoolean(false)
	
	let ssdpHandler = DynamicObject("SSDPHandler"):
		define("_multicastAddress", null):
		define("_threadMSearchHandler", null):
		define("_socketMSearch", null):
		define("_isRunning", isRunning):
		define("_observable", observable):
		define("_clients", 0):
		define("start", |this| -> initAndStartThreads(this)):
		define("stop", |this| -> scheduleStopThreads(this)):
		define("mSearch", |this, searchText, seconds| -> mSearch(this, searchText, seconds)):
		define("registerCallback", |this, searchText, cb| -> registerCallback(this, searchText, cb))
		
	return ssdpHandler
}

local function initAndStartThreads = |handler| {
	# To do: locking...
	let clients = handler: _clients() + 1
	handler: _clients(clients)
	if (clients > 1) {
		# println("Already started...")
		return
	}
	
	let multicastAddress = InetAddress.getByName(MULTICAST_ADDRESS_IP4)
	let isRunning = handler: _isRunning()
	
	# Init M-SEARCH handling thread
	let socketMSearch = MulticastSocket()
	socketMSearch: setSoTimeout(10 * 1000)
	
	isRunning: set(true)
	
	let threadMSearchHandler = runInNewThread({
		# println("MSEARCH thread starts")
		var index = 0
		while(isRunning: get()) {
			let buffer = newTypedArray(byte.class, BUFFER_SIZE)
			let recv = DatagramPacket(buffer, buffer: length())
			try {
				# println("MSEARCH THREAD: Waiting for data...")
				socketMSearch: receive(recv)
			} catch (ex) {
				case {
					when ex oftype SocketTimeoutException.class {
						# println(ex)
						continue
					} otherwise {
						throw ex
					}
				}
			}
			let incomingMsg = String(buffer, "UTF-8")
			let status, headers = _getValues(incomingMsg)

			if (status: size() > 1 and status: get(1) == "200") {
				handler: _observable(): set(headers)
			}
		}
		# println("MSEARCH THREAD: stopped")
	})
	
	handler: _multicastAddress(multicastAddress)
	handler: _socketMSearch(socketMSearch)
	handler: _threadMSearchHandler(threadMSearchHandler)
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

local function scheduleStopThreads = |handler| {
	# To do: locking...

	var clients = handler: _clients()

	if (clients >= 1) {
		clients = clients - 1
		handler: _clients(clients)
	}
	
	if (clients == 0) {
		handler: _isRunning(): set(false)
	}
}

local function mSearch = |handler, searchText, seconds| {
	# println("Sending MSearch query... ")
	let msg = createMSearchString(MULTICAST_ADDRESS_IP4, MULTICAST_UDP_PORT, searchText, seconds)
	# println("'" + msg + "'")
	let msgBytes = msg: getBytes("UTF-8")
	let multicastAddress = handler: _multicastAddress()
	let mSearchPacket = DatagramPacket(msgBytes, msgBytes: length(), multicastAddress, MULTICAST_UDP_PORT)
	
	let socketMSearch = handler: _socketMSearch()
	socketMSearch: send(mSearchPacket)
}

local function registerCallback = |handler, st, cb| {
	handler: _observable(): onChange(|v| {
		if st == null or (v: containsKey("st") and v: getOrElse("st", "") == st) {
			cb(v)
		}
	})
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