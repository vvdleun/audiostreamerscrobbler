module experiments.MusicCastDiscovery

import java.net.{DatagramPacket, InetAddress, MulticastSocket}
import java.nio.charset.StandardCharsets

let MULTICAST_ADDRESS_IP4 = "239.255.255.250"
let MULTICAST_ADDRESS_IP6 = "FF05::C"
let MULTICAST_UDP_PORT = 1900
let BUFFER_SIZE = 1 * 1024

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

	let multicastAddress = InetAddress.getByName(MULTICAST_ADDRESS_IP4)
	let multicastSocket = MulticastSocket(MULTICAST_UDP_PORT)
	multicastSocket: joinGroup(multicastAddress)

	println("Sending MSearch query...")
	let msg = createMSearchString(MULTICAST_ADDRESS_IP4, MULTICAST_UDP_PORT, "MediaRenderer", 2)
	println("'" + msg + "'")
	let msgBytes = msg: getBytes("UTF-8")
	let mSearchPacket = DatagramPacket(msgBytes, msgBytes: length(), multicastAddress, MULTICAST_UDP_PORT)
	multicastSocket: send(mSearchPacket)

	var index = 0
	println("Waiting for replies...")
	while(true) {
		let buffer = newTypedArray(byte.class, BUFFER_SIZE)
		let recv = DatagramPacket(buffer, buffer: length())
		multicastSocket: receive(recv)
		let incomingMsg = String(buffer, "UTF-8")
		if (incomingMsg: contains("MediaRenderer") and incomingMsg: toUpperCase(): contains("LOCATION")) {
			index = index + 1
			println("Packet #" + index)
			println(incomingMsg)
		}
	}
}

local function createMSearchString = |multicastAddress, multicastPort, searchTarget, seconds| {
	let msg = StringBuilder()
	msg: append("M-SEARCH * HTTP/1.1\r\n")
	msg: append("Host: ")
	msg: append(MULTICAST_ADDRESS_IP4)
	msg: append(":")
	msg: append(multicastPort: toString())
	msg: append("\r\n")
	msg: append("Man: ssdp:discover\r\n")
	msg: append("MX: ")
	msg: append(seconds: toString())
	msg: append("\r\n")
	msg: append("ST: urn:schemas-upnp-org:device:")
	msg: append(searchTarget)
	msg: append(":1\r\n")
	return msg: toString()
}