module audiostreamerscrobbler.players.heos.HeosMonitor

import audiostreamerscrobbler.players.heos.HeosConnectionSingleton
import audiostreamerscrobbler.players.heos.HeosSlaveMonitor

function createHeosMonitor = |player, cb| {
	let heosConnection = getHeosConnectionInstance()
	let heosMasterMonitor = heosConnection: heosMasterMonitor()

	let heosSlaveMonitor = createHeosSlaveMonitor(heosConnection, player, cb)

	let monitor = DynamicObject("HeosMonitor"):
		define("_masterMonitor", |this| -> heosMasterMonitor):
		define("_slaveMonitor", |this| -> heosSlaveMonitor):
		define("player", |this| -> player):
		define("start", |this| -> startMonitor(this)):
		define("stop", |this| -> stopMonitor(this))

	return monitor
}

local function startMonitor = |monitor| {
	let masterMonitor = monitor: _masterMonitor()
	let slaveMonitor = monitor: _slaveMonitor()

	masterMonitor: addSlave(slaveMonitor)
}

local function stopMonitor = |monitor| {
	let masterMonitor = monitor: _masterMonitor()
	let slaveMonitor = monitor: _slaveMonitor()

	masterMonitor: removeSlave(slaveMonitor)
}
