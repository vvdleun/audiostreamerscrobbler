module audiostreamerscrobbler.state.PlayerDetectorState

import audiostreamerscrobbler.detector.types.PlayerDetectorStates
import audiostreamerscrobbler.player.Player
import audiostreamerscrobbler.state.PlayerMonitorState
import audiostreamerscrobbler.state.types.StateStates

function createPlayerDetectorState = |detector| {
	let state = DynamicObject("DetectPlayerState"):
		define("_detector", detector):
		define("run", |this| {
			let detectorState = this: _detector(): detectPlayer()
			if (detectorState == PlayerDetectorStates.playerNotFoundKeepTrying()) {
				return StateStates.RepeatLastState()
			}
			
			# TODO make sure state is PlayerDetectorStates.playerFound()
			let playerImpl = detectorState: player()
			
			let player = createPlayer(playerImpl)
			
			println("Found player: " + player)
			
			let nextState = createPlayerMonitorState(player)
			return StateStates.NewState(nextState)
		})

	return state
}



