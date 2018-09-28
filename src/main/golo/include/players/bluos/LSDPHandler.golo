module audiostreamerscrobbler.players.bluos.LSDPHandler

import audiostreamerscrobbler.utils.{ByteUtils, ThreadUtils}
import nl.vincentvanderleun.lsdp.exceptions.{LSDPException, LSDPNoAnswerException}

import java.io.IOException
import java.lang.Thread
import java.net.{DatagramPacket, SocketTimeoutException, BindException}
import java.util.Arrays
import java.util.concurrent.atomic.{AtomicBoolean, AtomicReference}

# Let's hope LSDP answers will not get any bigger than this...
let LSDP_ANSWER_BUFFER_SIZE = 4096
# 06 "LSDP" 01 05 "Q" 01 FF FF
let LSDP_DATA_QUERY_PLAYERS = newByteArrayFromUnsignedByteHexStringArray(array["06", "4C", "53", "44", "50", "01", "05", "51", "01", "FF", "FF"])
# "LSDP" identification string in header (starts on second byte of LSDP query/answer)
let LSDP_DATA_HEADER_ID = newByteArrayFromUnsignedByteHexStringArray(array["4C", "53", "44", "50"])
# UDP port reserved for LSDP protocol
let LSDP_PORT = 11430
# Amount of seconds that program will sleep after I/O error 
let ERROR_SLEEP_TIME_SECONDS = 10
# After this amount of timeouts while waiting for a LSDP answer, the LSDP query will be re-sent
let MAX_TIMEOUTS = 10

function createLSDPHandler = |socketFactory, timeout, cb| {
	let isRunning = AtomicReference(AtomicBoolean(false))

	let handler = DynamicObject("LSDPHandler"):
		define("_isRunning", isRunning):
		define("_thread", null):
		define("_socketFactory", socketFactory):
		define("_timeout", timeout):
		define("_cb", cb):
		define("start", |this| -> initAndStartHandler(this)):
		define("stop", |this| -> stopHandler(this))

	return handler
}

# Sending LSDP queries

local function initAndStartHandler = |handler| {
	if (handler: _isRunning(): get(): get()) {
		raise("Internal error: LSDP handler is already running!")
	}

	let thread = runInNewThread("LSDPThread", {
		var multicastSocket = null
		let isRunning = -> handler: _isRunning(): get()
		let socketFactory = handler: _socketFactory()
		let timeout = handler: _timeout()
		let cb = handler: _cb()
		let broadcastAddresses = socketFactory: getBroadcastAddresses()
		
		println("Starting LSDP discovery thread...")
		isRunning(): set(true)
		while (isRunning(): get()) {
			try {
				if (multicastSocket == null) {
					# println("Opening LSDP socket...")
					# datagramSocket = socketFactory: createDatagramSocket(LSDP_PORT)
					# println("Opened LSDP socket...")
					# multicastSocket = MulticastSocket(LSDP_PORT)
					multicastSocket = socketFactory: createMulticastSocketAndBindToPort(LSDP_PORT)
				}

				# println("Querying...")
				sendLSDPQueryPlayers(broadcastAddresses, multicastSocket)

				waitForLSDPPlayers(handler, multicastSocket, timeout, cb)
			} catch (ex) {
				case {
					when ex oftype BindException.class {
						println("ERROR: Could not bind to LSDP port. Make sure no other BluOS/Bluesound applications are active on this system.")
					}
					when ex oftype IOException.class {
						println("I/O error while sending LSDP player queries: " + ex)
					}
					otherwise {
						throw ex
					}
				}
				Thread.sleep(ERROR_SLEEP_TIME_SECONDS * 1000_L)
			}
		}
		println("Stopping LSDP discovery thread...")
		if (multicastSocket != null) {
			multicastSocket: close()
		}
	})
	handler: _thread(thread)
}

local function stopHandler = |lsdpHandler| {
	lsdpHandler: _isRunning(): get(): set(false)
}

# Lower level functions

local function sendLSDPQueryPlayers = |broadcastAddresses, multicastSocket| {
	broadcastAddresses: each(|a| -> sendLSDPQuery(multicastSocket, a, LSDP_DATA_QUERY_PLAYERS))
}

local function sendLSDPQuery = |multicastSocket, broadcastAddress, dataQuery| {
	let port = multicastSocket: getLocalPort()
	let datagramPacket = DatagramPacket(dataQuery, dataQuery: length(), broadcastAddress, port)
	multicastSocket: send(datagramPacket)
}

# Receiving LSDP answers

local function waitForLSDPPlayers = |handler, multicastSocket, timeoutSeconds, cb| {
	let isRunning = -> handler: _isRunning(): get()

	let answerBuffer = newTypedArray(byte.class, LSDP_ANSWER_BUFFER_SIZE)
	let answerPacket = DatagramPacket(answerBuffer, answerBuffer: length())

	multicastSocket: setSoTimeout(timeoutSeconds * 1000 )

	var timeouts = 0
	var waitForMorePlayers = true
	while (waitForMorePlayers and isRunning(): get()) {
		try {
			# println("Waiting for LSDP data...")
			multicastSocket: receive(answerPacket)
			timeouts = 0
			let lsdpPlayer = extractLSDPPlayer(answerPacket)
			cb(lsdpPlayer, answerPacket)
		} catch (ex) {
			case {
				when ex oftype LSDPException.class {
					case {
						when ex oftype LSDPNoAnswerException.class {
							# println("* Incoming data was not LSDP answer: " + ex: getMessage())
						}
						when ex oftype IOException.class {
							println("I/O error while handling LSDP traffic: " + ex + ". Stay idle for " + ERROR_SLEEP_TIME_SECONDS + " seconds...")
							Thread.sleep(ERROR_SLEEP_TIME_SECONDS * 1000_L)
						}
						otherwise {
							println("* Unknown LSDP related error: " + ex: getMessage())
							throw ex
						}
					}
				}
				when ex oftype SocketTimeoutException.class {
					# println("* Timeout occurred")
					timeouts = timeouts + 1
					# println("Timeouts: " + timeouts)
					if (timeouts > MAX_TIMEOUTS) {
						# println("Stop trying...")
						waitForMorePlayers = false
					}
				}
				otherwise {
					throw ex
				}
			}
		}
	}
}

local function extractLSDPPlayer = |datagramPacket| {
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
	
	return map[
		["lsdpVersionSupposedly", version],
		["answerType", answerType],
		["macAddress", readMacAddress(context)],
		["ipAddress", readIPAddress(context)],
		["tables", readTables(context, msgEndOffset)]
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
		if (context: buffer(): get(idx) == LSDP_DATA_HEADER_ID: get(0)) {
			let headerBytes = Arrays.copyOfRange(context: buffer(), idx, idx + LSDP_DATA_HEADER_ID: length())
			# When bytes have been found that start with "LSDP", assume that we have received LSDP-related data
			if (Arrays.equals(LSDP_DATA_HEADER_ID, headerBytes)) {
				context: index(idx + LSDP_DATA_HEADER_ID: length())
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
		
		# Not sure yet whether this are really bytes that can identify a table
		# At this time it seems appropiate, but it could be wrong.
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
		let key = readCountedString(context)
		let value = readCountedString(context)
		keyValueMap: put(key, value)
	}
	return map[["id1", tableId1], ["id2", tableId2], ["map", keyValueMap]]
}

# Low level read functions (those do context's index management)

local function readCountedString = |context| {
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
	return readBytes(context, 1): get(0)
}

local function readBytes = |context, length| {
	let idx = context: index()
	context: index(idx + length)
	return Arrays.copyOfRange(context: buffer(), idx, idx+length)
}

local function skipBytes = |context, length| {
	context: index(context: index() + length)
}

# Random helper functions that probably never should have been put here in the first place...

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
