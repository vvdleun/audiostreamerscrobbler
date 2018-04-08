module audiostreamerscrobbler.scrobbler.MissedScrobblerHandler

import gololang.concurrent.workers.WorkerEnvironment
import java.lang.Thread
import java.util.concurrent
import java.util.concurrent.atomic.AtomicBoolean

union MissedScrobblerActions = {
	AddMissedScrobbleMsg = {scrobblerId, scrobble}
	ScrobbleMissedScrobblesMsg
}

function createMissedScrobblerHandlerThread = |size, interval, scrobblers| {
	let scrobblersMap = map[[s: id(), s] foreach s in scrobblers]

	let missedScrobblerHandler = DynamicObject("MissedScrobblerHandler"):
		define("_size", size):
		define("_interval", interval):
		define("_thread", null):
		define("_isRunning", null):
		define("_env", null):
		define("_port", null):
		define("_scrobblers", scrobblersMap):
		define("_scrobbles", null):
		define("_scheduleScrobbleAction", |this| -> scheduleScrobbleAction(this)):
		define("start", |this| -> startScrobblerHandler(this)):
		define("stop", |this| -> stopScrobblerHandler(this)):
		define("addMissedScrobble", |this, scrobblerIds, scrobble| -> scheduleAddScrobble(this, scrobblerIds, scrobble))

	return missedScrobblerHandler
}

local function startScrobblerHandler = |handler| {
	if (handler: _thread() isnt null) {
		raise("Internal error: scrobble missing task thread was already running")
	}
	initScrobblerHandler(handler)
	handler: _thread(): start()
}

local function initScrobblerHandler = |handler| {
	handler: _scrobbles(map[])

	let env = WorkerEnvironment.builder(): withSingleThreadExecutor() 
	let actionPort = env: spawn(^portIncomingMsgHandler: bindTo(handler))

	handler: _env(env)
	handler: _port(actionPort)
	
	handler: _isRunning(AtomicBoolean(false))
	
	let missedScrobbleRunThread = _createMissedScrobbleRunThread(handler)
	handler: _thread(missedScrobbleRunThread)
}

local function _createMissedScrobbleRunThread = |handler| {
	let runThread = {
		let isRunning = handler: _isRunning()
		isRunning: set(true)
		while (isRunning: get()) {
			handler: _scheduleScrobbleAction()
			Thread.sleep(handler: _interval() * 1000_L)
		}
		handler: _env(): shutdown()
		handler: _port(null)
		handler: _thread(null)
	}
	let runnable = asInterfaceInstance(Runnable.class, runThread)
	return Thread(runnable)
}

local function scheduleAddScrobble = |handler, scrobblerIds, scrobble| {
	if (not handler: _isRunning(): get()) {
		raise("Internal error: MissingScrobblerThread is not running")
	}
	handler: _port(): send(AddMissedScrobbleMsg(scrobblerIds, scrobble))
}

local function scheduleScrobbleAction = |handler| {
	if (not handler: _isRunning(): get()) {
		raise("Internal error: MissingScrobblerThread is not running")
	}

	handler: _port(): send(ScrobbleMissedScrobblesMsg())	
}

local function stopScrobblerHandler = |handler| {
	handler: _isRunning(): set(false)
}

# Port message handler

local function portIncomingMsgHandler = |handler, msg| {
	case {
		when msg: isAddMissedScrobbleMsg() {
			# println("Adding scrobble...")
			_addScrobbles(handler, msg)
		}
		when msg: isScrobbleMissedScrobblesMsg() {
			# println("\n\n\nscrobbling...")
			# scrobbles: clear()
		}
		otherwise {
			raise("Internal error, unknown message passed: " + msg)
		}
	}
	# println(scrobbles)
}

local function _addScrobbles = |handler, msg| {
	let scrobblerId = msg: scrobblerId()
	let scrobbles = handler: _scrobbles()
	scrobbles: putIfAbsent(scrobblerId, set[])
	scrobbles: get(scrobblerId): add(msg: scrobble())
}

local function _scrobbleMissingScrobbles = |handler| {
	handler: _scrobbles(): entrySet(): each(|es| {
		let scrobblerId = es: getKey()
		let scrobbles = es: getValue()
		let scrobbler = handler: _scrobblers(): get(scrobblerId)
		scrobbler: scrobbleAll(scrobbles)
	})
} 

function main = |args| {
	let s1 = DynamicObject():
		define("getId", |this| -> "xxxx")
	let s2 = DynamicObject():
		define("getId", |this| -> "yyy")

	let handler = createMissedScrobblerHandlerThread(100, 2, [s1, s2])
	handler: start()

	foreach i in range(10000) {
		handler: addMissedScrobble([s1, s2], "nu", "prachtig lied " + i)
		Thread.sleep(15_L)
	}
	
	Thread.sleep(60000_L * 5)
	
	handler: stop()
}