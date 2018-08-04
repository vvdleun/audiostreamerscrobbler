module audiostreamerscrobbler.factories.SocketFactory

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.utils.NetworkUtils

function createSocketFactory = {
	let config = getConfig()

	let socketFactory = DynamicObject("SocketFactory"):
		define("_config", config):
		define("createSocket", |this, host, port| -> createSocket(host, port, this: _config())):
		define("createMulticastSocket", |this| -> createMulticastSocket(this: _config())):
		define("createMulticastSocketAndBindToPort", |this, port| -> createMulticastSocketAndBindToPort(port, this: _config())):
		define("createDatagramSocket", |this, port| -> createDatagramSocket(port, this: _config())):
		define("createDatagramSocketAnyPort", |this| -> createDatagramSocket(0, this: _config())):
		define("getBroadcastAddresses", |this| -> _getBroadcastAddresses(this: _config()))
		
	return socketFactory
}

local function createSocket = |host, port, config| {
	let interfaceName, interfaceAddress = _getNetworkSettings(config)
	return createSocket(host, port, interfaceName, interfaceAddress)
}

local function createMulticastSocket = |config| {
	let interfaceName, interfaceAddress = _getNetworkSettings(config)
	return createMulticastSocket(interfaceName, interfaceAddress)
}

local function createMulticastSocketAndBindToPort = |port, config| {
	let interfaceName, interfaceAddress = _getNetworkSettings(config)
	return createMulticastSocket(port, interfaceName, interfaceAddress)
}

local function createDatagramSocket = |port, config| {
	let interfaceName, interfaceAddress = _getNetworkSettings(config)
	return createDatagramSocket(port, interfaceName, interfaceAddress)
}

local function _getBroadcastAddresses = |config| {
	let interfaceName = _getNetworkSettings(config): get(0)
	return getNetworkInterfaceBroadcastAddresses(interfaceName)
}

local function _getNetworkSettings = |config| {
	let settings = config: getOrElse("settings", map[])
	let networkSettings = settings: getOrElse("network", map[])
	let interfaceName = networkSettings: getOrElse("networkInterface", "")
	let interfaceAddress = networkSettings: getOrElse("networkInterfaceAddress", "")
	return [interfaceName, interfaceAddress]
}
