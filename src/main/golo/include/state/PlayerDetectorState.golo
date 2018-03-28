module audiostreamerscrobbler.state.PlayerDetectorState

import audiostreamerscrobbler.detector.types.PlayerDetectorStates
import audiostreamerscrobbler.player.Player
import audiostreamerscrobbler.state.PlayerMonitorState
import audiostreamerscrobbler.state.types.StateStates

function createPlayerDetectorState = |detector, playerFactory| {
	let state = DynamicObject("DetectPlayerState"):
		define("_detector", detector):
		define("_playerFactory", playerFactory):
		define("run", |this| {
			let detectorState = this: _detector(): detectPlayer()
			if (detectorState == PlayerDetectorStates.playerNotFoundKeepTrying()) {
				return StateStates.RepeatLastState()
			}
			
			# TODO make sure state is PlayerDetectorStates.playerFound()
			let detectedPlayer = detectorState: player()
			
			println("Found player: " + detectedPlayer)
			
			let player = createPlayer(this: _playerFactory(): createPlayer(detectedPlayer))
			
			println("AudioScrobbler player: " + player)
			
			let nextState = createPlayerMonitorState(player)
			return StateStates.NewState(nextState)
		})

	return state
}



