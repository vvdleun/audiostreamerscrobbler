module experiments.MusicCastDiscovery

import gololang.Observable
import java.lang.Thread
import java.net.{DatagramPacket, InetAddress,  MulticastSocket, SocketTimeoutException}
import java.util.concurrent.atomic.AtomicBoolean

let MULTICAST_ADDRESS_IP4 = "239.255.255.250"
let MULTICAST_ADDRESS_IP6 = "FF05::C"
let MULTICAST_UDP_PORT = 1900
let BUFFER_SIZE = 4 * 1024

let SEARCH_TEXT_MUSICCAST = "urn:schemas-upnp-org:device:MediaRenderer:1"

function main = |args| {
	
	# 0000   4d 2d 53 45 41 52 43 48 20 2a 20 48 54 54 50 2f   M-SEARCH * HTTP/
	# 0010   31 2e 31 0d 0a 48 6f 73 74 3a 20 32 33 39 2e 32   1.1..Host: 239.2
	# 0020   35 35 2e 32 35 35 2e 32 35 30 3a 31 39 30 30 0d   55.255.250:1900.
	# 0030   0a 53 54 3a 20 75 72 6e 3a 73 63 68 65 6d 61 73   .ST: urn:schemas
	# 0040   2d 75 70 6e 70 2d 6f 72 67 3a 64 65 76 69 63 65   -upnp-org:device
	# 0050   3a 49 6e 74 65 72 6e 65 74 47 61 74 65 77 61 79   :InternetGateway
	# 0060   44 65 76 69 63 65 3a 31 0d 0a 4d 61 6e 3a 20 22   Device:1..Man: "
	# 0070   73 73 64 70 3a 64 69 73 63 6f 76 65 72 22 0d 0a   ssdp:discover"..
	# 0080   4d 58 3a 20 33 0d 0a 0d 0a                        MX: 3....

	let keepSearching = AtomicBoolean(true)
	let ssdpHandler = createSSDPHandler()
	
	ssdpHandler: registerCallback(|headers| {
		if headers: get("st") == SEARCH_TEXT_MUSICCAST {
			println("CALLBACK: " + headers)
			keepSearching: set(false)
		}
	})
	
	ssdpHandler: start()
	
	while (keepSearching: get()) {
		foreach (i in range(3)) {
			if (not keepSearching: get()) {
				break
			}
			ssdpHandler: mSearch(SEARCH_TEXT_MUSICCAST, 1)
			Thread.sleep(1000_L)
		}
		Thread.sleep(6000_L)
	}
	println("Stopped search")
	
	ssdpHandler: stop()
}

local function createSSDPHandler = {
	let observable = Observable("SSDPObservable")
	let isRunning = AtomicBoolean(false)
	
	let ssdpHandler = DynamicObject("SSDPHandler"):
		define("_multicastAddress", null):
		define("_threadMSearchHandler", null):
		define("_socketMSearch", null):
		define("_isRunning", isRunning):
		define("_observable", observable):
		define("start", |this| -> initAndStartThreads(this)):
		define("stop", |this| -> scheduleStopThreads(this)):
		define("mSearch", |this, searchText, seconds| -> mSearch(this, searchText, seconds)):
		define("registerCallback", |this, f| -> registerCallback(this, f))
		
	return ssdpHandler
}

local function initAndStartThreads = |handler| {
	let multicastAddress = InetAddress.getByName(MULTICAST_ADDRESS_IP4)
	let isRunning = handler: _isRunning()
	
	# Init M-SEARCH handling thread
	let socketMSearch = MulticastSocket()
	socketMSearch: setSoTimeout(30 * 1000 )
	
	isRunning: set(true)
	
	let threadMSearchHandler = runInNewThread({
		println("MSEARCH thread starts")
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
		println("MSEARCH THREAD: stopped")
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
	handler: _isRunning(): set(false)
}

local function mSearch = |handler, searchText, seconds| {
	println("Sending MSearch query... ")
	let msg = createMSearchString(MULTICAST_ADDRESS_IP4, MULTICAST_UDP_PORT, searchText, seconds)
	# println("'" + msg + "'")
	let msgBytes = msg: getBytes("UTF-8")
	let multicastAddress = handler: _multicastAddress()
	let mSearchPacket = DatagramPacket(msgBytes, msgBytes: length(), multicastAddress, MULTICAST_UDP_PORT)
	
	let socketMSearch = handler: _socketMSearch()
	socketMSearch: send(mSearchPacket)
}

local function registerCallback = |handler, f| {
	handler: _observable(): onChange(f)
}

local function createMSearchString = |multicastAddress, multicastPort, searchTarget, seconds| {
	let msg = StringBuilder()
	msg: append("M-SEARCH * HTTP/1.1\r\n")
	msg: append("Host: ")
	msg: append(MULTICAST_ADDRESS_IP4)
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

#####

function runInNewThread = |f| {
	let runnable = asInterfaceInstance(Runnable.class, f)
	let thread = Thread(runnable)
	thread: start()
	return thread
}