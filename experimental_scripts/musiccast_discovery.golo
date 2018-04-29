module experiments.MusicCastDiscovery

import audiostreamerscrobbler.utils.SimpleXMLParser

import gololang.Observable
import java.lang.Thread
import java.net.{DatagramPacket, InetAddress,  MulticastSocket, SocketTimeoutException, URL}
import java.util.concurrent.atomic.AtomicBoolean

let MULTICAST_ADDRESS_IP4 = "239.255.255.250"
let MULTICAST_ADDRESS_IP6 = "FF05::C"
let MULTICAST_UDP_PORT = 1900
let BUFFER_SIZE = 4 * 1024

let SEARCH_TEXT_MUSICCAST = "urn:schemas-upnp-org:device:MediaRenderer:1"

let XML_YAMAHA_X_PATH = "root/yamaha:X_device"
let XML_YAMAHA_X_SERVICE_PATH = XML_YAMAHA_X_PATH + "/yamaha:X_serviceList/yamaha:X_service"
let XML_YAMAHA_X_SPEC_TYPE_PATH = XML_YAMAHA_X_SERVICE_PATH + "/yamaha:X_specType"
let XML_YAMAHA_X_CONTROL_URL_PATH = XML_YAMAHA_X_SERVICE_PATH + "/yamaha:X_yxcControlURL"

let XML_SPEC_TYPE_EXTENDED_CONTOL = "urn:schemas-yamaha-com:service:X_YamahaExtendedControl:1"

let XML_ELEMENTS_TO_KEYS = map[
	["root/device/manufacturer", "manufacturer"],
	["root/device/modelName", "model"],
	["root/device/friendlyName", "name"],
	["root/yamaha:X_device/yamaha:X_URLBase", "urlBase"]]

function main = |args| {
	let ssdpHandler = createSSDPHandler()
	let musicCastPlayer = discoverMusicCast(ssdpHandler, "Bedroom ISX-18D")
	println("Creating monitor for " + musicCastPlayer + "...")
	
}
	
function discoverMusicCast = |ssdpHandler, deviceName| {
	let keepSearching = AtomicBoolean(true)
	let device = list[]
	
	ssdpHandler: registerCallback(SEARCH_TEXT_MUSICCAST, |headers| {
		# This callback is supposed to be threadsafe by Golang's Observable
		# implementation...
		println("CALLBACK: " + headers)
		if (not keepSearching: get()) {
			println("Device is already found. Ignored incoming SSDP handler")
			println(headers)
			return
		}

		let uri = URL(headers: get("location"))

		let musicCastXml = map[]
		let service = map[["isService", false]]

		parseXmlElements(uri: openStream(), |event| {
			let path = event: path()

			if event: isStartElement() {
				if (path == XML_YAMAHA_X_PATH) {
					# MusicCast specs asks to validate explicitly that this element exists
					musicCastXml: put(XML_YAMAHA_X_PATH, true)
				} else if (path == XML_YAMAHA_X_SERVICE_PATH) {
					# Sub elements are parsed in the temporary "service" map
					service: put("isService", true)
				}
			} else if event: isEndElement() {
				if (path == XML_YAMAHA_X_SERVICE_PATH) {
					# Check whether this service was the one we were looking for
					if (service: get(XML_YAMAHA_X_SPEC_TYPE_PATH) == XML_SPEC_TYPE_EXTENDED_CONTOL) {
						musicCastXml: put("yxcControlUrl", service: get(XML_YAMAHA_X_CONTROL_URL_PATH))
					}
					service: clear()
					service: put("isService", false)

				} else if (service: get("isService")) {
					# Store sub elements of <yamaha:X_service> element in temporary "service" map
					service: put(path, event: characters())

				} else {
					# Map simple fields that need no additional parsing logic
					let key = XML_ELEMENTS_TO_KEYS: get(path)
					if key != null {
						musicCastXml: put(key, event: characters())
					}
				}
			}
		})
		
		keepSearching: set(false)
		device: add(musicCastXml)
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
		if (keepSearching: get()) {
			Thread.sleep(10000_L)
		}
	}
	# println("Stopped search")
	
	ssdpHandler: stop()
	return device: get(0)

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