module audiostreamerscrobbler.utils.NetworkUtils

import java.io.IOException
import java.net.{MulticastSocket, NetworkInterface, Socket}

# Network Interfaces

function getBroadcastAddresses = {
	try {
		let result = list[]
		foreach networkInterface in getNetworkInterfaces() {
			let broadcastAddresses = getBroadcastAddresses(networkInterface)
			if (broadcastAddresses != null) {
				result: addAll(broadcastAddresses)
			}
		}
		return result
	} catch(ex) {
		throw IOException(ex)
	}
}

function getBroadcastAddresses = |networkInterface| {
	try {
		let result = list[]
		if (networkInterface is null) {
			return result
		}
		let addresses = networkInterface: getInterfaceAddresses()
		if (addresses is null) {
			return result
		}
		foreach address in addresses {
			let broadcastAddress = address: getBroadcast()
			if (broadcastAddress != null) {
				result: add(broadcastAddress)
			}
		}
		return result
	} catch(ex) {
		throw IOException(ex)
	}
}

function getNetworkInterfaces = {
	try {
		let result = list[]
		let interfaces = NetworkInterface.getNetworkInterfaces()
		while (interfaces: hasMoreElements()) {
			let networkInterface = interfaces: nextElement()
			if (not networkInterface: isLoopback() and networkInterface: isUp()) {
				result: add(networkInterface)
			}
		}
		return result
	} catch(ex) {
		throw IOException(ex)
	}
}

function getInetAddresses = |networkInterface| {
	try {
		let result = list[]
		let addresses = networkInterface: getInetAddresses()
		while (addresses: hasMoreElements()) {
			let inetAddress = addresses: nextElement()
			if (inetAddress != null) {
				result: add(inetAddress)
			}
		}
		return result
	} catch(ex) {
		throw IOException(ex)
	}
}

# Sockets
# TODO: Refactor this rather ugly API. It relies way too much on the SocketFactory
#       implementation. 

function createSocket = |host, port, interfaceName, interfaceAddress| {
	if (isNullOrEmpty(interfaceAddress)) {
		return Socket(host, port)
	}
	let inetAddress = getNetworkInterfaceInetAddress(interfaceName, interfaceAddress)
	return Socket(host, port, inetAddress, 0)
}

function createMulticastSocket = |interfaceName, interfaceAddress| {
	let multicastSocket = MulticastSocket()

	if (isNullOrEmpty(interfaceName) and isNullOrEmpty(interfaceAddress)) {
		return multicastSocket
	}

	bindMulticastSocketToInterface(multicastSocket, interfaceName, interfaceAddress)

	return multicastSocket
}

function createMulticastSocket = |port, interfaceName, interfaceAddress| {
	let multicastSocket = MulticastSocket(port)

	if (isNullOrEmpty(interfaceName) and isNullOrEmpty(interfaceAddress)) {
		return multicastSocket
	}

	bindMulticastSocketToInterface(multicastSocket, interfaceName, interfaceAddress)

	return multicastSocket
}

function bindMulticastSocketToInterface = |multicastSocket, interfaceName, interfaceAddress| {
	let inetAddress = getNetworkInterfaceInetAddress(interfaceName, interfaceAddress)
	multicastSocket: setInterface(inetAddress)
	
	return multicastSocket
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
		throw IOException("Network interface '" + interfaceName + "' could not be found")
	}
	let inetAddresses = getInetAddresses(networkInterface)
	let inetAddress = getInetAddress(inetAddresses, interfaceAddress)
	if (inetAddress is null) {
		throw IOException("Network address '" + interfaceAddress + "' could not be found on network interface '" + networkInterface + "'")
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