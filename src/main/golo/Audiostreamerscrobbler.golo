#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.factories.PlayerDetectorFactory
import audiostreamerscrobbler.factories.ScrobblersFactory
import audiostreamerscrobbler.scrobbler.MissedScrobblerHandler
import audiostreamerscrobbler.scrobbler.ScrobblersHandler
import audiostreamerscrobbler.states.detector.PlayerDetectorState
import audiostreamerscrobbler.states.monitor.PlayerMonitorState
import audiostreamerscrobbler.states.StateManager
import audiostreamerscrobbler.states.types.PlayerThreadStates

import java.util.Arrays

function main = |args| {
	run(args)
}

local function run = |args| {
	let isHandled = handleCommandLineOptions(args)
	if (isHandled) {
		return
	}

	# Create and start thread that periodically tries to scrobble scrobbles that were not accepted previously
	# TODO make this configurable...
	let scrobblers = createScrobblersFactory(): createScrobblers()
	let missedScrobblesHandler = createMissedScrobblerHandlerThread(100, 10 * 60, scrobblers)
	missedScrobblesHandler: start()
	
	let stateManager = createStateManager(PlayerThreadStates.DetectPlayer(), |stateType| {
		# Create requested state
		let createPlayerDetector = -> createPlayerDetectorFactory(): createPlayerDetector()
		let createHandlerWithScrobblers = -> createScrobblersHandler(createScrobblersFactory(): createScrobblers(), missedScrobblesHandler)
		let state = match {
			when stateType: isDetectPlayer() then createPlayerDetectorState(createPlayerDetector())
			when stateType: isMonitorPlayer() then createPlayerMonitorState(stateType: player(), createHandlerWithScrobblers())
			otherwise raise("Internal error: unknown request PlayerThreadState state: " + stateType)
		}
		return state
	})
	
	stateManager: run()
}

local function handleCommandLineOptions = |args| {
	let parser = DynamicObject("VerySimpleArgsParser"):
		define("_args", args):
		define("_index", 0):
		define("parseNext", |this| {
			let index = this: _index()
			let args = this: _args()
			if (index >= args: length()) {
				return null
			}
			let v = args: get(index)
			this: _index(index + 1)
			return v
		})

		
	if (parser: parseNext() == "--authorize") {
		let service = parser: parseNext()
		if (service == null) {
			println("Syntax: Audiostreamerscrobbler --authorize [" + getScrobblerKeyNames(): join("|") + "]") 
			return true
		}
		let scrobblersFactory = createScrobblersFactory()
		let authorizer = scrobblersFactory: createScrobblerAuthorizer(service)
		if (authorizer == null) {
			println("Specified scrobbler service '" + service + "' is unknown. Known services are: " + getScrobblerKeyNames(): join("/")) 
			return true
		}

		authorizer: authorize()
		return true
	}

	return false
}