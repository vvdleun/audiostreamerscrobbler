module audiostreamerscrobbler.utils.NetworkUtils

import java.net.{DatagramSocket, DatagramPacket, InetSocketAddress, MulticastSocket, NetworkInterface}

# Network Interfaces

function getBroadcastAddresses = {
	let result = list[]
	foreach networkInterface in getNetworkInterfaces() {
		let broadcastAddresses = getBroadcastAddresses(networkInterface)
		if (broadcastAddresses != null) {
			result: addAll(broadcastAddresses)
		}
	}
	return result
}

function getBroadcastAddresses = |networkInterface| {
	let result = list[]
	let addresses = networkInterface: getInterfaceAddresses()
	foreach address in addresses {
		let broadcastAddress = address: getBroadcast()
		if (broadcastAddress != null) {
			result: add(broadcastAddress)
		}
	}
	return result
}

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

function getInetAddresses = |networkInterface| {
	let result = list[]
	let addresses = networkInterface: getInetAddresses()
	while (addresses: hasMoreElements()) {
		let inetAddress = addresses: nextElement()
		if (inetAddress != null) {
			result: add(inetAddress)
		}
	}
	return result
}

# Sockets
# TODO: Refactor this rather ugly API. It relies way too much on the SocketFactory
#       implementation. 

function createMulticastSocket = |interfaceName, interfaceAddress| {
	let multicastSocket = MulticastSocket()

	if (isNullOrEmpty(interfaceName) and isNullOrEmpty(interfaceAddress)) {
		return multicastSocket
	}

	let inetAddress = getNetworkInterfaceInetAddress(interfaceName, interfaceAddress)
	multicastSocket: setInterface(inetAddress)

	return multicastSocket
}

function createDatagramSocket = |port, interfaceName, interfaceAddress| {
	# println("port: " + port)
	# println("interfaceName: " + interfaceName)
	# println("interfaceAddress: " + interfaceAddress)
	
	# println("Creating datagram socket bound to address and port")
	let inetAddress = getNetworkInterfaceInetAddress(interfaceName, interfaceAddress)
	let inetSocketAddress = InetSocketAddress(inetAddress, port)
	return DatagramSocket(inetSocketAddress)
}

function getNetworkInterfaceBroadcastAddresses = |interfaceName| {
	if (not isNullOrEmpty(interfaceName)) {
		let networkInterfaces = getNetworkInterfaces()
		let networkInterface = getNetworkInterface(networkInterfaces, interfaceName)
		return getBroadcastAddresses(networkInterface)
	} else {
		return getBroadcastAddresses()
	}

}

local function getNetworkInterfaceInetAddress = |interfaceName, interfaceAddress| {
	let networkInterfaces = getNetworkInterfaces()
	let networkInterface = getNetworkInterface(networkInterfaces, interfaceName)
	if (networkInterface is null) {
		raise("Network interface '" + interfaceName + "' could not be found")
	}
	let inetAddresses = getInetAddresses(networkInterface)
	let inetAddress = getInetAddress(inetAddresses, interfaceAddress)
	if (inetAddress is null) {
		raise("Network address '" + interfaceAddress + "' could not be found on network interface '" + networkInterface + "'")
	}
	
	return inetAddress
}

local function getNetworkInterface = |networkInterfaces, interfaceName| {
	if (isNullOrEmpty(interfaceName)) {
		return networkInterfaces: get(0)
	}
	let names = [i foreach i in networkInterfaces when i: name() == interfaceName or i: displayName() == interfaceName]
	if (names: isEmpty()) {
		return null
	}
	return names: get(0)
}

local function getInetAddress = |inetAddresses, interfaceAddress| {
	if (isNullOrEmpty(interfaceAddress)) {
		return inetAddresses: get(0)
	}
	let addresses = [a foreach a in inetAddresses when a: getHostAddress() == interfaceAddress]
	if (addresses: isEmpty()) {
		return null
	}
	return addresses: get(0)
}

local function isNullOrEmpty = |v| -> v is null or v: isEmpty()