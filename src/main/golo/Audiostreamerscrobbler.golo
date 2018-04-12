#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.factories.PlayerDetectorFactory
import audiostreamerscrobbler.factories.ScrobblerErrorHandlerFactory
import audiostreamerscrobbler.factories.ScrobblersFactory
import audiostreamerscrobbler.scrobbler.ScrobblersHandler
import audiostreamerscrobbler.states.detector.PlayerDetectorState
import audiostreamerscrobbler.states.monitor.PlayerMonitorState
import audiostreamerscrobbler.states.StateManager
import audiostreamerscrobbler.states.types.PlayerThreadStates
import audiostreamerscrobbler.utils.VerySimpleArgsParser

import java.util.Arrays

function main = |args| {
	run(args)
}

local function run = |args| {
	let isHandled = handleCommandLineOptions(args)
	if (isHandled) {
		return
	}

	let scrobblers = createScrobblersFactory(): createScrobblers()
	let missedScrobblerHandler = createScrobblerErrorHandlerFactory(scrobblers): createScrobblerErrorHandler()
	missedScrobblerHandler: start()
	
	let stateManager = createStateManager(PlayerThreadStates.DetectPlayer(), |stateType| {
		# Create requested state
		let createPlayerDetector = -> createPlayerDetectorFactory(): createPlayerDetector()
		let createHandlerWithScrobblers = -> createScrobblersHandler(createScrobblersFactory(): createScrobblers(), missedScrobblerHandler)
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
	let parser = createVerySimpleArgsParser(args)
		
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