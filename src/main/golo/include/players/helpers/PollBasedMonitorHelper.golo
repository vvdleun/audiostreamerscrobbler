module audiostreamerscrobbler.players.helpers.PollBasedMonitorHelper

import audiostreamerscrobbler.utils.ThreadUtils

import java.lang.Thread
import java.time.{Duration, Instant}
import java.util.concurrent.atomic.AtomicBoolean

function createPollBasedPlayerMonitorHelper = |poller, minInterval, cb| {
	let pollingMonitor = DynamicObject("PollMonitorAdapter"):
		define("_poller", poller):
		define("_minInterval", minInterval * 1000_L):
		define("_isRunning", AtomicBoolean(false)):
		define("_thread", null):
		define("_lastCall", null):
		define("_cb", |this| -> cb):
		define("player", |this| -> this: _poller(): player()):
		define("start", |this| -> initAndStartPolling(this)):
		define("stop", |this| -> stop(this))

	return pollingMonitor
}

local function initAndStartPolling = |pollHelper| {
	if (pollHelper: _thread() isnt null) {
		raise("Internal error: thread already exists")
	}
	
	let thread = runInNewThread("PollBasedMonitorHelper", {
		let isRunning = pollHelper: _isRunning()
		let cb = pollHelper: _cb()

		isRunning: set(true)
		println("Starting player polling thread...")
		while (isRunning: get()) {
			waitIfLastCallWasTooSoon(pollHelper)
			try {
				pollPlayerAnCallCallback(pollHelper, cb)
			} catch(ex) {
				let player = pollHelper: player()
				println("Error occurred while polling " + player + ": " + ex)
				throw ex
			}
		}
		println("Stopped player polling thread")
	})
	pollHelper: _thread(thread)
}

local function stop = |pollHelper| {
	let isRunning = pollHelper: _isRunning()
	let thread = pollHelper: _thread()
	isRunning: set(false)
	pollHelper: _thread(null)
}

function waitIfLastCallWasTooSoon = |pollHelper| {
	let currentCall = Instant.now()
	let lastCall = pollHelper: _lastCall()

	# println("Now          : " + currentCall)
	# println("Last call was: " + lastCall)
	
	try {
		if (lastCall != null) {
			let timeDiff = Duration.between(lastCall, currentCall): toMillis()
			# println("That was     : " +  timeDiff + " milliseconds ago")
			let minInterval = pollHelper: _minInterval()
			if (timeDiff < minInterval and timeDiff >= 0) {
				# Calculate how long to wait before the requested minimal
				# interval can (roughly) be respected
				let waitInterval = minInterval - timeDiff
				if (waitInterval > 0_L) {
					# println("Waiting for " + waitInterval + " milliseconds")
					Thread.sleep(waitInterval)
				}
			}
		}
	} finally {
		pollHelper: _lastCall(currentCall)
	}
}

function pollPlayerAnCallCallback = |pollHelper, cb| {
	# println("Polling...")
	let poller = pollHelper: _poller()
	let playerStatus = poller: poll()
	cb(playerStatus)
}