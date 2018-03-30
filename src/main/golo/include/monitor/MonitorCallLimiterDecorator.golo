module audiostreamerscrobbler.state.monitor.MonitorCallLimiterDecorator

import audiostreamerscrobbler.monitor.types.MonitorStates

import java.lang.Thread
import java.time.{Instant, Duration}
import java.util.concurrent.ConcurrentHashMap

function monitorCallLimiterDecorator = |milliSeconds| {
	let dataStore = ConcurrentHashMap()
	
	return |func| {
		return |args...| {
			let monitor = args: get(0)
			let player = monitor: player()
			let playerId = player: id()

			let currentCall = Instant.now()
			
			if (dataStore: containsKey(playerId)) {
				let lastCall = dataStore: get(playerId)
				let timeDiff = Duration.between(lastCall, currentCall): toMillis()
				
				# println("Last call was " + timeDiff + " milliseconds ago. Must delay: " + (timeDiff < milliSeconds))
				if (timeDiff < milliSeconds and timeDiff >= 0) {
					let waitInterval = milliSeconds - timeDiff * 1_L
					println("Delaying call " + waitInterval + " milliseconds")
					if (waitInterval > 0_L) {
						Thread.sleep(waitInterval)
					}
					return MonitorStates.MONITOR_IGNORE_ITERATION()
				}
			}

			dataStore: put(playerId, Instant.now())
			let res = func: invoke(args)

			return res
		}
	}
}
