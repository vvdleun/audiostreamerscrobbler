module audiostreamerscrobbler.states.detector.PlayerDetectorState

import audiostreamerscrobbler.maintypes.Player
import audiostreamerscrobbler.states.types.PlayerThreadStates

function createPlayerDetectorState = |playerDetector| {
	let state = DynamicObject("DetectPlayerState"):
		define("_playerDetector", playerDetector):
		define("run", |this| -> runPlayerDetectorState(this))

	return state
}

local function runPlayerDetectorState = |playerDetectorState| {
	let detector = playerDetectorState: _playerDetector()
	println("Looking for players...")
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