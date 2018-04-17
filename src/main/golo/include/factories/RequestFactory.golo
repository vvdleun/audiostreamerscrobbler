module audiostreamerscrobbler.factories.RequestFactory

import audiostreamerscrobbler.utils.RequestUtils

import gololang.JSON
import java.io.{BufferedReader, InputStreamReader, IOException}
import java.util.stream.Collectors

let USER_AGENT = "AudiostreamerScrobbler/0.1"
let DEFAULT_TIMEOUT_SECONDS = 10
let DEFAULT_ENCODING = "utf-8"

let DEFAULT_PROPERTIES_CALLBACK = -> map[["User-Agent", USER_AGENT]]

function createHttpRequestFactory = {
	return createHttpRequestFactory(DEFAULT_ENCODING, DEFAULT_TIMEOUT_SECONDS)
}

function createHttpRequestFactory = |encoding, timeout| {
	let httpRequestFactory = DynamicObject("HttpRequestFactory"):
		define("encoding", encoding):
		define("timeout", timeout):
		define("createHttpRequest", |this| -> createHttpRequest(this: encoding(), this: timeout()))
	
	return httpRequestFactory
}


local function createHttpRequest = |encoding, timeout| {
	let httpRequest = DynamicObject("HttpRequest"):
		define("_timeout", timeout):
		define("_encoding", encoding):
		define("doHttpGetRequestAndReturnJSON", |this, url| -> doHttpGetRequestAndReturnJSON(url, this: _encoding(), this: _timeout())):
		define("doHttpPostRequestAndReturnJSON", |this, url, outputCallback| -> doHttpPostRequestAndReturnJSON(url, this: _encoding(), this: _timeout(), outputCallback)):
		define("doHttpGetRequestAndReturnAsText", |this, url| -> doHttpGetRequestAndReturnAsText(url, this: _encoding(), this: _timeout())):
		define("doHttpPostRequestAndReturnAsText", |this, url, outputCallback| -> doHttpPostRequestAndReturnAsText(url, this: _encoding(), this: _timeout(), outputCallback)):
		define("doHttpGetRequest", |this, url, inputCallback| -> doHttpGetRequest(url, this: _timeout(), inputCallback)):
		define("doHttpPostRequest", |this, url, outputCallback, inputCallback| -> doHttpPostRequest(url, this: _timeout(), outputCallback, inputCallback))
		
	return httpRequest
}

# GET

local function doHttpGetRequestAndReturnJSON = |url, encoding, timeout| {
	let jsonString = doHttpGetRequestAndReturnAsText(url, encoding, timeout)
	return JSON.parse(jsonString)
}

local function doHttpGetRequestAndReturnAsText = |url, encoding, timeout| {
	return doHttpGetRequest(url, timeout, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}

local function doHttpGetRequest = |url, timeout, inputStreamHandlerCallback| {
	return doHttpGetRequest(url, timeout, DEFAULT_PROPERTIES_CALLBACK, inputStreamHandlerCallback)
}


# POST

local function doHttpPostRequestAndReturnJSON = |url, encoding, timeout, outputStreamHandlerCallback| {
	let jsonString = doHttpPostRequestAndReturnAsText(url, encoding, timeout, outputStreamHandlerCallback)
	return JSON.parse(jsonString)
}

local function doHttpPostRequestAndReturnAsText = |url, encoding, timeout, outputStreamHandlerCallback| {
	return doHttpPostRequest(url, timeout, outputStreamHandlerCallback, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}

local function doHttpPostRequest = |url, timeout, outputStreamHandlerCallback, inputStreamHandlerCallback| {
	return doHttpPostRequest(url, timeout, DEFAULT_PROPERTIES_CALLBACK, outputStreamHandlerCallback, inputStreamHandlerCallback)
}
