#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.factories.PlayerDetectorFactory
import audiostreamerscrobbler.factories.ScrobblersFactory
import audiostreamerscrobbler.states.detector.PlayerDetectorState
import audiostreamerscrobbler.states.StateManager

import java.util.Arrays

let SCROBBLER_NAMES = ["gnufm"]

function main = |args| {
	run(args)
}

local function run = |args| {
	let isHandled = handleCommandLineOptions(args)
	if (isHandled) {
		return
	}

	let playerDetectorFactory = createPlayerDetectorFactory()
	let scrobblersFactory = createScrobblersFactory()
	
	let initialState = createPlayerDetectorState(playerDetectorFactory, scrobblersFactory)
	let stateManager = createStateManager(initialState)

	while (stateManager: hasState()) {
		stateManager: run()
	}

	
}

local function handleCommandLineOptions = |args| {
	let parser = DynamicObject("ArgsParser"):
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
			println("Syntax: Audiostreamerscrobbler --authorize [" + SCROBBLER_NAMES: join("|") + "]") 
			return true
		}
		let scrobblersFactory = createScrobblersFactory()
		let authorizer = scrobblersFactory: createScrobblerAuthorizer(service)
		if (authorizer == null) {
			println("Specified scrobbler service '" + service + "' is unknown. Known services are: " + SCROBBLER_NAMES: join("/")) 
			return true
		}

		authorizer: authorize()
		return true
	}

	return false
}