module audiostreamerscrobbler.bluesound.DetectorGaap

import audiostreamerscrobbler.network.NetworkUtils

import java.net.{DatagramPacket, DatagramSocket, InetAddress, InterfaceAddress}
import java.util.{Enumeration, Arrays}

import nl.vincentvanderleun.byteutils.UnsignedByte

let dataQuery = UnsignedByte.toSignedByteArray("06", "4C", "53", "44", "50", "01", "05", "51", "01", "FF", "FF")

function detectPlayersXXX = |playerNames| {
	sendBroadcast()
}

local function sendBroadcast = {
	let broadcastAddresses = getBroadcastAddresses()
	let clientSocket = DatagramSocket(11430)
	foreach broadcastAddress in broadcastAddresses {
		println("Sending to " + broadcastAddress)
		let dataGramPacket = DatagramPacket(dataQuery, dataQuery: length(), broadcastAddress, 11430)
		clientSocket: send(dataGramPacket)
	}
	println("Receiving...")
	let answerBuffer = newTypedArray(byte.class, 4096)
	let answerPacket = DatagramPacket(answerBuffer, answerBuffer: length())
	while (true) {
		clientSocket: receive(answerPacket)
		println("Received from " + answerPacket: getAddress())
		println(Arrays.toString(UnsignedByte.toUnsignedByteArray(answerPacket: getData())))
	}
}

