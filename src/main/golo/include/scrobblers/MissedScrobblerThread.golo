module audiostreamerscrobbler.scrobbler.MissedScrobblerHandler

import gololang.concurrent.workers.WorkerEnvironment
import java.lang.Thread
import java.util.{Calendar, TimeZone}
import java.util.concurrent
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.TimeUnit

union MissedScrobblerActionMsgs = {
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
		define("start", |this| -> initAndStartScrobblerHandler(this)):
		define("stop", |this| -> scheduleScrobbleStop(this)):
		define("addMissedScrobble", |this, scrobblerIds, scrobble| -> scheduleAddScrobble(this, scrobblerIds, scrobble))

	return missedScrobblerHandler
}

local function initAndStartScrobblerHandler = |handler| {
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
	let isRunning = handler: _isRunning()
	isRunning: set(true)

	let runThread = {
		while (isRunning: get()) {
			handler: _scheduleScrobbleAction()
			try {
				Thread.sleep(handler: _interval() * 1000_L)
			} catch (ex) {
				case {
					when ex oftype java.lang.InterruptedException.class {
					}
					otherwise {
						throw ex
					}
				}
			}
		}
		println("Stopped Scrobbler Error Handler thread...")
		handler: _env(): shutdown()
		handler: _port(null)
		handler: _thread(null)
	}
	let runnable = asInterfaceInstance(Runnable.class, runThread)
	return Thread(runnable)
}

local function scheduleAddScrobble = |handler, scrobblerId, scrobble| {
	if (not handler: _isRunning(): get()) {
		raise("Internal error: MissingScrobblerThread is not running")
	}
	handler: _port(): send(MissedScrobblerActionMsgs.AddMissedScrobbleMsg(scrobblerId, scrobble))
}

local function scheduleScrobbleAction = |handler| {
	if (not handler: _isRunning(): get()) {
		raise("Internal error: MissingScrobblerThread is not running")
	}

	handler: _port(): send(MissedScrobblerActionMsgs.ScrobbleMissedScrobblesMsg())	
}

local function scheduleScrobbleStop = |handler| {
	handler: _thread(): interrupt()
	handler: _isRunning(): set(false)
}

# Port message handler

local function portIncomingMsgHandler = |handler, msg| {
	case {
		when msg: isAddMissedScrobbleMsg() {
			_addScrobbles(handler, msg)
		}
		when msg: isScrobbleMissedScrobblesMsg() {
			_scrobbleMissingScrobbles(handler)
		}
		otherwise {
			raise("Internal error, received unknown message: " + msg)
		}
	}
}

local function _addScrobbles = |handler, msg| {
	let scrobblerId = msg: scrobblerId()
	let scrobbles = handler: _scrobbles()
	if (scrobbles: size() < handler: _size()) {
		scrobbles: putIfAbsent(scrobblerId, set[])
		scrobbles: get(scrobblerId): add(msg: scrobble())
	} else {
		println("SCROBBLE WILL BE LOST: TOO MANY SCROBBLES IN QUEUE")
	}
}

local function _scrobbleMissingScrobbles = |handler| {
	handler: _scrobbles(): entrySet(): each(|es| {
		let scrobblerId = es: getKey()
		let scrobbles = es: getValue()
		if (scrobbles: size() > 0) {
			println("\n* Re-scrobbling " + scrobbles: size() + " songs to " + scrobblerId + "...")
			let scrobbler = handler: _scrobblers(): get(scrobblerId)
			let filteredScrobbles = scrobbles: filter(|s| -> daysBetweenNowAndDate(s: utcTimestamp()) <= scrobbler: maximalDaysOld())
			try {
				scrobbler: scrobbleAll(filteredScrobbles)
				println("* Done\n")
				scrobbles: clear()
			} catch (ex) {
				println("* COULD NOT RE-SCROBBLE: " + ex + "\n")
			}
		}
	})
}

local function daysBetweenNowAndDate = |d| {
	let dateNow = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
	
	let diff = dateNow: getTimeInMillis() - d: getTimeInMillis()
    return TimeUnit.DAYS(): convert(diff, TimeUnit.MILLISECONDS())
}
