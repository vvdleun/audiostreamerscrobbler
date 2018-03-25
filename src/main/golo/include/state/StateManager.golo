module audiostreamerscrobbler.state.StateManager

function createStateManager = |firstState| {
	let stateManager = DynamicObject("StateManager"):
		define("_state", firstState):
		define("run", |this| {
			let nextState = this: _state(): run()
			this: _state(nextState)
		}):
		define("hasState", |this| -> this: _state() isnt null)
	
	return stateManager
}