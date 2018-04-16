#!/usr/bin/env golosh
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.factories.Config
import audiostreamerscrobbler.factories.PlayerDetectorFactory
import audiostreamerscrobbler.factories.ScrobblerErrorHandlerFactory
import audiostreamerscrobbler.factories.ScrobblersFactory
import audiostreamerscrobbler.scrobbler.ScrobblersHandler
import audiostreamerscrobbler.states.detector.PlayerDetectorState
import audiostreamerscrobbler.states.monitor.PlayerMonitorState
import audiostreamerscrobbler.states.StateManager
import audiostreamerscrobbler.states.types.PlayerThreadStates
import audiostreamerscrobbler.utils.VerySimpleArgsParser

import gololang.IO
import java.util.Arrays

function main = |args| {
	run(args)
}

local function run = |args| {
	let isHandled = handleCommandLineOptions(args)
	if (isHandled) {
		return
	}
	
	let isConfigFileValid = validateConfig()
	if (not isConfigFileValid) {
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

local function validateConfig = {
	if not fileExists("config.json") {
		println("Configuration file \"config.json\" was not found in the current directory.")
		println("See project's website \"https://github.com/vvdleun/audiostreamerscrobbler\" for an example.")
		println("\nAt this time, this file must be created and configured manually.")
		return false
	}

	try {
		let config = getConfig()
	} catch(ex) {
		println("Error while reading config.json. Please check whether the file is valid JSON and uses UTF-8 encoding.")
		println("\nPlease accept our apologies for the fact that this file has to be edited manually for now. For the future an user-friendly GUI editor feature is planned.")
		println("\nReported error: " + ex)
		return false
	}
	return true
}

local function handleCommandLineOptions = |args| {
	let parser = createVerySimpleArgsParser(args)

	var option = parser: parseNext()

	while (option != null) {
		case {
			when option == "--authorize" {
				return authorizeService(parser)
			}

			otherwise {
				return showHelp(option)
			}
		}
		option = parser: parseNext()
	}
	
	return false
}

local function showHelp = |option| {
	if (option != "--help") {
		println("Unrecognized option: \"" + option + "\"\n")
	}

	println("Valid options:\n")
	println("--authorize [" + getScrobblerKeyNames():join("|") + "]")
	println("    Starts the authorization process for the specified music tracking service.\n")
	println("--help")
	println("    Shows this help screen\n")

	return true
}

local function authorizeService = |parser| {
	_authorizeService(parser)
	return true
}

local function _authorizeService = |parser| {
	let service = parser: parseNext()
	if (service is null) {
		println("No service specified. Valid syntax: --authorize [" + getScrobblerKeyNames(): join("|") + "]\n") 
		println("Example: --authorize " + getScrobblerKeyNames(): get(0))
		return
	}

	let isConfigFileValid = validateConfig()
	if (not isConfigFileValid) {
		return
	}
	
	let scrobblersFactory = createScrobblersFactory()
	let authorizer = scrobblersFactory: createScrobblerAuthorizer(service)
	if (authorizer == null) {
		println("Specified scrobbler service '" + service + "' is unknown. Known services are: " + getScrobblerKeyNames(): join(", ")) 
		return
	}

	authorizer: authorize()
}

