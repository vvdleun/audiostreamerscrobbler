module audiostreamerscrobbler.bluesound.Detector

import audiostreamerscrobbler.network.NetworkUtils

import java.net.{DatagramPacket, DatagramSocket, SocketTimeoutException}
import java.util.Arrays

import nl.vincentvanderleun.utils.ByteUtils

let LSDP_PORT = 11430
let LSDP_DATA_QUERY_PLAYERS = UnsignedByte.toSignedByteArray("06", "4C", "53", "44", "50", "01", "05", "51", "01", "FF", "FF")
let TIMEOUT_SECONDS = 3

function detectPlayers = |playerNames| {
	let datagramSocket = DatagramSocket(LSDP_PORT)

	queryPlayersOnAllBroadcastAddresses(datagramSocket)
	let players = waitForLSDPPlayers(datagramSocket, TIMEOUT_SECONDS)
}

# Sending LSDP queries

local function queryPlayersOnAllBroadcastAddresses = |datagramSocket| {
	let broadcastInetAddresses = getBroadcastAddresses()
	foreach broadcastInetAddress in broadcastInetAddresses {
		println("Sending to " + broadcastInetAddress)
		sendLSDPQueryPlayers(datagramSocket, broadcastInetAddress)
	}
}

local function sendLSDPQueryPlayers = |datagramSocket, inetAddress| {
	sendLSDPQuery(datagramSocket, inetAddress, LSDP_DATA_QUERY_PLAYERS)
}

local function sendLSDPQuery = |datagramSocket, inetAddress, dataQuery| {
	sendLSDPQuery(datagramSocket, inetAddress, LSDP_PORT, dataQuery)
}

local function sendLSDPQuery = |datagramSocket, inetAddress, port, dataQuery| {
	let datagramPacket = DatagramPacket(dataQuery, dataQuery: length(), inetAddress, port)
	datagramSocket: send(datagramPacket)
}

# Receiving LSDP answers

local function waitForLSDPPlayers = |datagramSocket, timeoutSeconds| {
	println("Receiving...")
	let answerBuffer = newTypedArray(byte.class, 4096)
	let answerPacket = DatagramPacket(answerBuffer, answerBuffer: length())
	datagramSocket: setSoTimeout(timeoutSeconds * 1000 )
	let players = list[]
	var waitForMorePlayers = true
	while (waitForMorePlayers) {
		println("Waiting for input...")
		try {
			datagramSocket: receive(answerPacket)
			let player = extractLSDPPlayer(answerPacket)
			println(player)
			# println("Received from " + answerPacket: getAddress())
			# println(Arrays.toString(UnsignedByte.toUnsignedByteArray(answerPacket: getData())))
		} catch (e) {
			case {
				when e oftype SocketTimeoutException.class {
					waitForMorePlayers = false
				}
				otherwise {
					throw e
				}
			}
		}
	}
}

local function extractLSDPPlayer = |datagramPacket| {
	let buffer = datagramPacket: getData()
	if (compareSubsetArray(buffer, LSDP_DATA_QUERY_PLAYERS, 0, LSDP_DATA_QUERY_PLAYERS: length())) {
		return null
	}
	println("Not same as query")

	let header = readHeader(buffer)	
	if (header != "LSDP") {
		return null
	}

	let version = readVersion(buffer)
	if (version != 1) {
		return null
	}

	let answerType = readType(buffer)
	if (answerType != "A") {
		return null
	}
	
	let macAddress = readMacAddress(buffer)
	println(macAddress)
	
	# println(Arrays.toString(unsignedByteBuffer))
	return "pggg"
}

local function readHeader = |byteArray| {
	let headerBytes = Arrays.copyOfRange(byteArray, 1, 5)
	return String(headerBytes, "UTF-8")
}

local function readVersion = |byteArray| {
	return UnsignedByte.toUnsignedByte(byteArray: get(5))
}

local function readType = |byteArray| {
	let headerBytes = Arrays.copyOfRange(byteArray, 7, 8)
	return String(headerBytes, "UTF-8")
}

local function readMacAddress = |byteArray| {
	let length = UnsignedByte.toUnsignedByte(byteArray: get(8))
	println(length)
	let macAddress = UnsignedByte.toUnsignedByteArray(Arrays.copyOfRange(byteArray, 9, 9+length))
	return [atLeastTwoChars(Integer.toHexString(macAddress: get(i))) foreach i in range(length)]: join(":")
}

local function atLeastTwoChars = |s| {
	var result = s
	while (result: length() < 2) {
		result = "0" + s
	}
	return result 
}

local function compareSubsetArray = |array1, array2, start, length| {
	let subset1 = Arrays.copyOfRange(array1, start, length)
	let subset2 = Arrays.copyOfRange(array2, start, length)
	return Arrays.equals(subset1, subset2)
}
