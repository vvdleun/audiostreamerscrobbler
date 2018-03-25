module audiostreamerscrobbler.network.NetworkUtils

import java.net.NetworkInterface

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
