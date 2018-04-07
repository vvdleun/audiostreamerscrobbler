module audiostreamerscrobbler.scrobbler.MissedScrobblerHandler

import gololang.concurrent.workers.WorkerEnvironment
import java.lang.Thread
import java.util.concurrent
import java.util.concurrent.atomic.AtomicBoolean

union MissedScrobblerActions = {
	AddMissedScrobbleMsg = {scrobblerId, utcTimestamp, song}
	ScrobbleMissedScrobblesMsg
}

struct MissedScrobble = {
	scrobblerIds,
	utcTimestamp,
	song
}

function createMissedScrobblerHandlerThread = |size, interval, scrobblers| {
	let scrobblersMap = map[[s: getId(), s] foreach s in scrobblers]

	let missedScrobblerHandler = DynamicObject("MissedScrobblerHandler"):
		define("_size", size):
		define("_interval", interval):
		define("_scrobblers", scrobblersMap):
		define("_thread", null):
		define("_isRunning", null):
		define("_env", null):
		define("_port", null):
		define("_scrobbles", null):
		define("_scheduleScrobbleAction", |this| -> scheduleScrobbleAction(this)):
		define("start", |this| -> startScrobblerHandler(this)):
		define("stop", |this| -> stopScrobblerHandler(this)):
		define("addMissedScrobble", |this, scrobbleIds, utcTimestamp, song| -> addMissedScrobble(this, scrobbleIds, utcTimestamp, song))

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
	handler: _scrobbles(set[])

	let env = WorkerEnvironment.builder(): withSingleThreadExecutor() 
	let actionPort = env: spawn(^missedScrobblerDoAction: bindTo(handler: _scrobbles()))

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

local function addMissedScrobble = |handler, scrobbleIds, utcTimestamp, song| {
	if (not handler: _isRunning(): get()) {
		raise("Internal error: MissingScrobblerThread is not running")
	}
	handler: _port(): send(AddMissedScrobbleMsg(scrobbleIds, utcTimestamp, song))
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

# Port

local function missedScrobblerDoAction = |scrobbles, msg| {
	let thread = Thread.currentThread()
	case {
		when msg: isAddMissedScrobbleMsg() {
			scrobbles: add(MissedScrobble(msg: scrobblerId(), msg: utcTimestamp(), msg: song()))
		}
		when msg: isScrobbleMissedScrobblesMsg() {
			# ...
		}
		otherwise {
			raise("Internal error, unknown message passed: " + msg)
		}
	}
}