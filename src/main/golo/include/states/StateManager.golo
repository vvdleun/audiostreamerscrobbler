module audiostreamerscrobbler.states.StateManager

function createStateManager = |initialStateType, stateFactoryCallback| {
	let stateManager = DynamicObject("StateManager"):
		define("_stateType", initialStateType):
		define("run", |this| {
			while (true) {
				let state = stateFactoryCallback(this: _stateType())		
				let nextState = state: run()
				this: _stateType(nextState)
				if (nextState is null) {
					return
				}
			}
		})
	
	return stateManager
}

