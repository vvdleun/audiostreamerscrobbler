module audiostreamerscrobbler.states.detector.PlayerDetectorState

import audiostreamerscrobbler.states.detector.types.DetectorStateTypes
import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.states.monitor.PlayerMonitorState
import audiostreamerscrobbler.states.types.StateTypes

function createPlayerDetectorState = |detector| {
	let state = DynamicObject("DetectPlayerState"):
		define("_detector", detector):
		define("run", |this| {
			let detectorState = this: _detector(): detectPlayer()
			if (detectorState == DetectorStateTypes.playerNotFoundKeepTrying()) {
				return StateTypes.RepeatLastState()
			}
			
			# TODO make sure state is DetectorStateTypes.playerFound()
			let playerImpl = detectorState: player()
			
			let player = createPlayer(playerImpl)
			
			println("Found player: " + player)
			
			let nextState = createPlayerMonitorState(player)
			return StateTypes.NewState(nextState)
		})

	return state
}



