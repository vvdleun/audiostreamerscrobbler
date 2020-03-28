#!/usr/bin/env golosh 
module audiostreamerscrobbler.Audiostreamerscrobbler

import audiostreamerscrobbler.factories.{Config, PlayerControlThreadFactory, ScrobblersFactory, ScrobblerErrorHandlerFactory}
import audiostreamerscrobbler.utils.{NetworkUtils, VerySimpleArgsParser}

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
	
	let isConfigFileValid = validateAndInitConfig()
	if (not isConfigFileValid) {
		return
	}
	
	let scrobblerErrorHandler = createScrobblerErrorHandlerFactory(): createScrobblerErrorHandler()
	scrobblerErrorHandler: start()

	let playerControlThreadFactory = createPlayerControlThreadFactory()
	let playerControlThread = playerControlThreadFactory: createPlayerControlThread(scrobblerErrorHandler)
	playerControlThread: start()
}

local function validateAndInitConfig = {
	if not fileExists("config.json") {
		println("Configuration file \"config.json\" was not found in the current directory.")
		println("See project's website \"https://github.com/vvdleun/audiostreamerscrobbler\" for an example.")
		println("\nAt this time, this file must be created and configured manually.")
		return false
	}

	try {
		initConfig()
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
			when option == "--networkinterfaces" {
				return showNetworkInterfaces()
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
	println("--networkinterfaces")
	println("    Shows network interface names and addresses that can be used in configuration file")
	println("--help")
	println("    Shows this help screen\n")

	return true
}

local function authorizeService = |parser| {
	try {
		_authorizeService(parser)
	} catch(ex) {
		println("\nUnexpected error occurred: " + ex)
		println("")
		throw ex
	}
	return true
}

local function _authorizeService = |parser| {
	let service = parser: parseNext()
	if (service is null) {
		println("No service specified. Valid syntax: --authorize [" + getScrobblerKeyNames(): join("|") + "]\n") 
		println("Example: --authorize " + getScrobblerKeyNames(): get(0))
		return
	}

	let isConfigFileValid = validateAndInitConfig()
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

local function showNetworkInterfaces = {
	getNetworkInterfaces(): each(|i| {
		println("Alias    : \"" + i: getName() + "\"")
		println("Name     : \"" + i: getDisplayName() + "\"")
		println("Addresses: " + ["\"" + a: getHostAddress() + "\"" foreach a in getInetAddresses(i)]: join("  "))
		println("\n\n")
	})

	return true
}