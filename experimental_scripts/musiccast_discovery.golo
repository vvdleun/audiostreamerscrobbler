module experiments.MusicCastDiscovery

import java.lang.Thread
import java.net.{DatagramPacket, InetAddress,  MulticastSocket, NetworkInterface}

let MULTICAST_ADDRESS_IP4 = "239.255.255.250"
let MULTICAST_ADDRESS_IP6 = "FF05::C"
let MULTICAST_UDP_PORT = 1900
let BUFFER_SIZE = 4 * 1024

function main = |args| {
	# MediaRenderer
	
	# 0000   4d 2d 53 45 41 52 43 48 20 2a 20 48 54 54 50 2f   M-SEARCH * HTTP/
	# 0010   31 2e 31 0d 0a 48 6f 73 74 3a 20 32 33 39 2e 32   1.1..Host: 239.2
	# 0020   35 35 2e 32 35 35 2e 32 35 30 3a 31 39 30 30 0d   55.255.250:1900.
	# 0030   0a 53 54 3a 20 75 72 6e 3a 73 63 68 65 6d 61 73   .ST: urn:schemas
	# 0040   2d 75 70 6e 70 2d 6f 72 67 3a 64 65 76 69 63 65   -upnp-org:device
	# 0050   3a 49 6e 74 65 72 6e 65 74 47 61 74 65 77 61 79   :InternetGateway
	# 0060   44 65 76 69 63 65 3a 31 0d 0a 4d 61 6e 3a 20 22   Device:1..Man: "
	# 0070   73 73 64 70 3a 64 69 73 63 6f 76 65 72 22 0d 0a   ssdp:discover"..
	# 0080   4d 58 3a 20 33 0d 0a 0d 0a                        MX: 3....

	let networkInterfaces = getNetworkInterfaces()
	let usedNetworkInterface = networkInterfaces: get(0)

	let ssdpHandler = createSSDPHandler(usedNetworkInterface)
	ssdpHandler: start()
	
	while (true) {
		foreach (i in range(3)) {
			ssdpHandler: mSearch("urn:schemas-upnp-org:device:MediaRenderer:1", 2)
			Thread.sleep(1000_L)
		}
		Thread.sleep(6000_L)
	}
}

local function createSSDPHandler = |networkInterface| {
	let ssdpHandler = DynamicObject("SSDPHandler"):
		define("_networkInterface", networkInterface):
		define("_multicastAddress", null):
		define("_threadNotifyHandler", null):
		define("_threadMSearchHandler", null):
		define("_socketNotify", null):
		define("_socketMSearch", null):
		define("start", |this| -> initAndStartThreads(this)):
		define("mSearch", |this, deviceName, seconds| -> mSearch(this, deviceName, seconds))
		
	return ssdpHandler
}

local function initAndStartThreads = |handler| {
	let networkInterface = handler: _networkInterface()
	println("Using: " + networkInterface)
	
	let multicastAddress = InetAddress.getByName(MULTICAST_ADDRESS_IP4)

	# Incoming UPNP NOTIFY messages handling

	let socketNotify = MulticastSocket(MULTICAST_UDP_PORT)
	
	let threadNotifyHandler = runInNewThread({
		# println("NOTIFY thread starts")
		# socketNotify: joinGroup(multicastAddress)
		# socketNotify: setSoTimeout(30000)
		# var index = 0
		# while(true) {
			# let buffer = newTypedArray(byte.class, BUFFER_SIZE)
			# let recv = DatagramPacket(buffer, buffer: length())
			# try {
			# 	println("NOTIFY THREAD: Waiting for data...")
			# 	socketNotify: receive(recv)
			# }  catch (ex) {
			# 	case {
			# 		when ex oftype  java.net.SocketTimeoutException.class {
			# 			println("NOTIFY Timeout")
			# 			continue
			# 		}
			# 		otherwise {
			# 			throw ex
			# 		}
			# 	}
			# }
			# let incomingMsg = String(buffer, "UTF-8")
			# index = index + 1
			# # println("\n\n" + java.util.Date() + " NOTIFY RESULT #" + index)
			
			# if (incomingMsg: contains("MediaRenderer")) {
			# 	println("\n\nNOTIFY #" + index + "\n" + incomingMsg: trim())
			# }
		# }
	})
	
	# M-SEARCH handling
	
	let socketMSearch = MulticastSocket()

	socketMSearch: setSoTimeout(30000)
	
	let threadMSearchHandler = runInNewThread({
		println("MSEARCH thread starts")
		var index = 0
		while(true) {
			let buffer = newTypedArray(byte.class, BUFFER_SIZE)
			let recv = DatagramPacket(buffer, buffer: length())
			try {
				# println("MSEARCH THREAD: Waiting for data...")
				socketMSearch: receive(recv)
			} catch (ex) {
				case {
					when ex oftype java.net.SocketTimeoutException.class {
						# println("MSEARCH Timeout")
						continue
					}
					otherwise {
						throw ex
					}
				}
			}
			let incomingMsg = String(buffer, "UTF-8")

			index = index + 1
			println("\n\nMSEARCH RESULT #" + index)
			if (incomingMsg: contains("MediaRenderer")) {
				println("\n\nMSEARCH RESULT #" + index + "\n" + incomingMsg: trim())
				println(incomingMsg: trim())
			}
		}
	})

	Thread.sleep(2500_L)
	
	handler: _multicastAddress(multicastAddress)
	handler: _socketNotify(socketNotify)
	handler: _socketMSearch(socketMSearch)
	handler: _threadNotifyHandler(threadNotifyHandler)
	handler: _threadMSearchHandler(threadMSearchHandler)
}

local function getValues = |msg| {
}

local function mSearch = |handler, searchText, seconds| {
	println("Sending MSearch query...")
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

function getNetworkInterfaces = {
	let result = list[]
	let interfaces = NetworkInterface.getNetworkInterfaces()
	while (interfaces: hasMoreElements()) {
		let networkInterface = interfaces: nextElement()
		if (not networkInterface: isLoopback() and networkInterface: isUp()) {
			result: add(networkInterface)
		}
	}
	return result
}

function runInNewThread = |f| {
	let runnable = asInterfaceInstance(Runnable.class, f)
	let thread = Thread(runnable)
	thread: start()
	return thread
}