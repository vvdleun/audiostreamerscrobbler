module audiostreamerscrobbler.states.StateManager

import audiostreamerscrobbler.states.types.StateStates

function createStateManager = |firstState| {
	let stateManager = DynamicObject("StateManager"):
		define("_state", firstState):
		define("run", |this| {
			let nextState = this: _state(): run()
			case {
				when nextState: isNewState() {
					this: _state(nextState: state())
				}
				when nextState: isHaltProgram() {
					# TODO this sucks...
					this: _state(null)
				}
				when nextState: isRepeatLastState() {
				}
				otherwise {
					raise("Unknown state state!!!")
				}
			}
		}):
		define("hasState", |this| -> this: _state() isnt null)
	
	return stateManager
}

