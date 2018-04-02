module audiostreamerscrobbler.states.detector.PlayerDetectorState

import audiostreamerscrobbler.states.detector.types.DetectorStateTypes
import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.states.monitor.PlayerMonitorState
import audiostreamerscrobbler.states.types.StateTypes

function createPlayerDetectorState = |playerDetectorFactory, scrobblersFactory| {
	let state = DynamicObject("DetectPlayerState"):
		define("_playerDetectorFactory", playerDetectorFactory):
		define("_scrobblersFactory", scrobblersFactory):
		define("run", |this| -> runPlayerDetectorState(this))

	return state
}

local function runPlayerDetectorState = |playerDetectorState| {
	let playerDetectorFactory = playerDetectorState: _playerDetectorFactory()
	let scrobblersFactory = playerDetectorState: _scrobblersFactory()

	let detector = playerDetectorFactory: createPlayerDetector()

	let detectorState = detector: detectPlayer()
	if (detectorState: isPlayerNotFoundKeepTrying()) {
		return StateTypes.NewState(playerDetectorState)

	} else if (detectorState: isPlayerFound()) {
		let playerImpl = detectorState: Player()
		
		let player = createPlayer(playerImpl)
		println("Found player: " + player)
		
		let nextState = createPlayerMonitorState(player, playerDetectorFactory, scrobblersFactory)
		return StateTypes.NewState(nextState)
	}
	raise("Internal error: unknown Player Detector state: " + detectorState)

} 


