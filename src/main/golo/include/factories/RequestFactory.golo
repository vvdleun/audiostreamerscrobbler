module audiostreamerscrobbler.factories.RequestFactory

import audiostreamerscrobbler.utils.RequestUtils

import gololang.JSON
import java.io.{BufferedReader, InputStreamReader, IOException}
import java.util.stream.Collectors

let USER_AGENT = "AudiostreamerScrobbler/0.1"
let DEFAULT_TIMEOUT_SECONDS = 10
let DEFAULT_ENCODING = "utf-8"

local function createGetProperties = |accept, encoding| -> map[["Accept", accept], ["Accept-Charset", encoding], ["Cache-Control", "no-cache"], ["User-Agent", USER_AGENT]]

local function createPostProperties = |accept, encoding, contentType| -> map[["Accept", accept], ["Accept-Charset", encoding], ["Cache-Control", "no-cache"], ["Content-Type", contentType], ["User-Agent", USER_AGENT]]

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
		define("doHttpPostRequestAndReturnJSON", |this, url, contentType, outputCallback| -> doHttpPostRequestAndReturnJSON(url, this: _encoding(), this: _timeout(), outputCallback, contentType)):
		define("doHttpGetRequestAndReturnAsText", |this, url| -> doHttpGetRequestAndReturnAsText(url, this: _encoding(), this: _timeout(), createGetProperties("text/plain", this: _encoding()))):
		define("doHttpPostRequestAndReturnAsText", |this, url, outputCallback, contentType| -> doHttpPostRequestAndReturnAsText(url, this: _encoding(), createPostProperties("text/plain", this: _encoding(), contentType), this: _timeout(), outputCallback)):
		define("doHttpGetRequest", |this, url, accept, inputHandler | -> doHttpGetRequest(url, this: _timeout(), createGetProperties(accept, this: _encoding()), inputHandler)):
		define("doHttpPostRequest", |this, url, accept, contentType, outputHandler, inputHandler | -> doHttpPostRequest(url, this: _timeout(), createPostProperties(accept, this: _encoding(), contentType), outputHandler, inputHandler))
		
	return httpRequest
}

# GET

local function doHttpGetRequestAndReturnJSON = |url, encoding, timeout| {
	let jsonString = doHttpGetRequestAndReturnAsText(url, encoding, timeout, createGetProperties("application/json", encoding))
	return JSON.parse(jsonString)
}

local function doHttpGetRequestAndReturnAsText = |url, encoding, timeout, requestPropertiesHandler| {
	return doHttpGetRequest(url, timeout, requestPropertiesHandler, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}

# POST

local function doHttpPostRequestAndReturnJSON = |url, encoding, timeout, outputStreamHandlerCallback, contentType| {
	let jsonString = doHttpPostRequestAndReturnAsText(url, encoding, createPostProperties("application/json", encoding, contentType), timeout, outputStreamHandlerCallback)
	return JSON.parse(jsonString)
}

local function doHttpPostRequestAndReturnAsText = |url, encoding, requestPropertiesHandler, timeout, outputStreamHandlerCallback| {
	return doHttpPostRequest(url, timeout, requestPropertiesHandler, outputStreamHandlerCallback, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}