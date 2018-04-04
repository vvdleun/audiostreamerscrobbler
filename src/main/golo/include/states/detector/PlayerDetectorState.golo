module audiostreamerscrobbler.states.detector.PlayerDetectorState

import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.states.detector.types.DetectorStateTypes
import audiostreamerscrobbler.states.types.PlayerThreadStates

function createPlayerDetectorState = |playerDetectorFactory| {
	let state = DynamicObject("DetectPlayerState"):
		define("_playerDetectorFactory", playerDetectorFactory):
		define("run", |this| -> runPlayerDetectorState(this))

	return state
}

local function runPlayerDetectorState = |playerDetectorState| {
	let playerDetectorFactory = playerDetectorState: _playerDetectorFactory()
	let detector = playerDetectorFactory: createPlayerDetector()

	while (true) {
		let detectorState = detector: detectPlayer()
		
		if (detectorState: isPlayerFound()) {
			let playerImpl = detectorState: Player()
			
			let player = createPlayer(playerImpl)
			println("Found player: " + player)
			
			return PlayerThreadStates.MonitorPlayer(player)
		}

		raise("Internal error: unknown Player Detector state: " + detectorState)
	}
} 