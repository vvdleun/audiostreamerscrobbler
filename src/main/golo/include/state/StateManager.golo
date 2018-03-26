module audiostreamerscrobbler.state.StateManager

let _STATE_HALT = null

function createStateManager = |firstState| {
	let stateManager = DynamicObject("StateManager"):
		define("_state", firstState):
		define("run", |this| {
			let nextState = this: _state(): run()
			this: _state(nextState)
		}):
		define("hasState", |this| -> this: _state() isnt _STATE_HALT)
	
	return stateManager
}

function STATE_HALT = {
	return _STATE_HALT
}