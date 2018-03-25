module audiostreamerscrobbler.bluesound.Detector

import audiostreamerscrobbler.utils.NetworkUtils
import audiostreamerscrobbler.utils.ByteUtils
import nl.vincentvanderleun.lsdp.exceptions.{LSDPException, LSDPNoAnswerException}

import java.net.{DatagramPacket, DatagramSocket, SocketTimeoutException}
import java.util.Arrays

let LSDP_PORT = 11430
let LSDP_DATA_QUERY_PLAYERS = newByteArrayFromUnsignedByteHexStringArray(array["06", "4C", "53", "44", "50", "01", "05", "51", "01", "FF", "FF"])
let LSDP_HEADER_ID = newByteArrayFromUnsignedByteHexStringArray(array["4C", "53", "44", "50"])
let TIMEOUT_SECONDS = 3

struct LSDPPlayer = {
	name,
	port,
	macAddress,
	ipAddress,
	supposedlyVersion,
	host
}

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
	try {
		var lsdpQueryAnswer = _extractLSDPPlayer(datagramPacket)
		var port = lsdpQueryAnswer: get("tables"): get(0): get(1): get("port")
		let name = lsdpQueryAnswer: get("tables"): get(0): get(1): get("name")
		return LSDPPlayer(
			name,
			port,
			lsdpQueryAnswer: get("macAddress"),
			lsdpQueryAnswer: get("ipAddress"),
			lsdpQueryAnswer: get("supposedVersion"),
			datagramPacket: getAddress(): toString() + ":" + port
		)
	} catch (ex) {
		case {
			when ex oftype LSDPNoAnswerException.class {
				println("* No valid answer data: " + ex: message())
			}
			otherwise {
				throw RuntimeException(ex)
			}
		}
		return null
	}
}


local function _extractLSDPPlayer = |datagramPacket| {
	let context = DynamicObject("LSDPDataContext"):
		define("buffer", datagramPacket: getData()):
		define("index", 0)
	
	if (isIncomingDataLSDPQuery(context)) {
		throw LSDPNoAnswerException("Incoming data was query")
	}

	let isLSDPData = navigateToLDSPHeader(context)
	if (not isLSDPData) {
		throw LSDPNoAnswerException("LSDP header not found")
	}
	
	let version = readVersion(context)

	let msgEndOffset = readLengthAndCalculateEndOffset(context)
	
	let answerType = readType(context)
	if (answerType != "A") {
		throw LSDPNoAnswerException("LSDP header type was '" + answerType + "' instead of 'A'")
	}
	
	let macAddress = readMacAddress(context)
	let ipAddress = readIPAddress(context)

	let tables = readTables(context, msgEndOffset)
	
	return map[
		["supposedVersion", version],
		["answerType", answerType],
		["macAddress", macAddress],
		["ipAddress", ipAddress],
		["tables", tables]
	]
		
}

local function isIncomingDataLSDPQuery = |context| {
	return compareSubsetArray(context: buffer(), LSDP_DATA_QUERY_PLAYERS, 0, LSDP_DATA_QUERY_PLAYERS: length())
}

# Higher level read functions

local function navigateToLDSPHeader = |context| {
	# Naive search function. Normally the answer should be at byte #1
	# Byte 0 probably is length of header, but this has not been determined yet
	for (var idx = 0, idx < context: buffer(): length(), idx = idx + 1) {
		let b =  unsignedByteFromByte(context: buffer(): get(idx))
		if (b == unsignedByteFromByte(LSDP_HEADER_ID: get(0))) {
			let headerBytes = Arrays.copyOfRange(context: buffer(), idx, idx + LSDP_HEADER_ID: length())
			if (Arrays.equals(LSDP_HEADER_ID, headerBytes)) {
				context: index(idx + LSDP_HEADER_ID: length())
				return true
			}
		}
	}
	return false
}

local function readVersion = |context| {
	return readUnsignedByte(context)
}

local function readLengthAndCalculateEndOffset = |context| {
	let idx = context: index()
	let lengthInHeader = readUnsignedByte(context)
	return lengthInHeader + idx
}

local function readType = |context| {
	return readString(context, 1)
}

local function readMacAddress = |context| {
	let macAddress = readFieldAsUnsignedBytes(context)
	return formatMacAddress(macAddress)
}

local function readIPAddress = |context| {
	let ipAddress = readFieldAsUnsignedBytes(context)
	return [ipAddress: get(i) foreach i in range(ipAddress: length())]: join(".")
}

local function readTables = |context, msgEndOffset| {
	# This byte is probably the amount of tables in the message, but this could
	# not be proved.
	skipBytes(context, 1)

	let tables = map[]
	while (context: index() < msgEndOffset) {
		let table = readTable(context)
		
		let tableId1 = table: get("id1")
		let tableId2 = table: get("id2")
		
		tables: putIfAbsent(tableId1, map[])
		tables: get(tableId1): putIfAbsent(tableId2, table: get("map"))
	}
	return tables
}

local function readTable = |context| {
	let tableId1 = readUnsignedByte(context)
	let tableId2 = readUnsignedByte(context)
	let keyValuePairs = readUnsignedByte(context)
	let keyValueMap = map[]
	foreach (keyValuePair in range(keyValuePairs)) {
		let key = readStringWithLength(context)
		let value = readStringWithLength(context)
		keyValueMap: put(key, value)
	}
	return map[["id1", tableId1], ["id2", tableId2], ["map", keyValueMap]]
}

# Low level read functions (context management)

local function readStringWithLength = |context| {
	let length = readUnsignedByte(context)
	return readString(context, length)
}

local function readString = |context, length| {
	let stringBytes = readBytes(context, length)
	return String(stringBytes, "UTF-8")
}

local function readFieldAsUnsignedBytes = |context| {
	let length = readUnsignedByte(context)
	return newUnsignedByteArrayFromByteArray(readBytes(context, length))
}

local function readUnsignedByte = |context| {
	return unsignedByteFromByte(readByte(context))
}

local function readByte = |context| {
	let idx = context: index()
	let value = context: buffer(): get(idx)
	context: index(idx + 1)
	return value
}

local function readBytes = |context, length| {
	let idx = context: index()
	context: index(idx + length)
	return Arrays.copyOfRange(context: buffer(), idx, idx+length)
}

local function skipBytes = |context, length| {
	context: index(context: index() + length)
}

# Random helper functions that should probably not be here...

local function compareSubsetArray = |array1, array2, start, length| {
	let subset1 = Arrays.copyOfRange(array1, start, length)
	let subset2 = Arrays.copyOfRange(array2, start, length)
	return Arrays.equals(subset1, subset2)
}

local function formatMacAddress = |m| {
	return [addLeadingZeroes(Integer.toHexString(m: get(i)), 2) foreach i in range(m: length())]: join(":")
}

local function addLeadingZeroes = |s, count| {
	var result = s
	while (result: length() < count) {
		result = "0" + s
	}
	return result 
}
