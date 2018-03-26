module audiostreamerscrobbler.state.PlayerDetectorState

import audiostreamerscrobbler.detector.types.DetectorStates
import audiostreamerscrobbler.state.MonitorPlayerState

function createPlayerDetectorState = |detector, playerFactory| {
	let state = DynamicObject("DetectPlayerState"):
		define("_detector", detector):
		define("_playerFactory", playerFactory):
		define("run", |this| {
			let detectorState = this: _detector(): detectPlayer()
			if (detectorState == DetectorStates.DETECTOR_KEEP_RUNNING()) {
				return this
			}
			
			// TODO make sure state is DetectorStates.DETECTOR_MONITOR_PLAYER
			let detectedPlayer = detectorState: player()
			
			println("Found player: " + detectedPlayer)
			
			let player = this: _playerFactory(): createPlayer(detectedPlayer)
			
			println("AudioScrobbler player: " + player)
			
			return createMonitorPlayerState(player)
		})

	return state
}



