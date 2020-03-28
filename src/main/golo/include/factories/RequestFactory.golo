module audiostreamerscrobbler.factories.RequestFactory

import audiostreamerscrobbler.maintypes.AppMetadata
import audiostreamerscrobbler.utils.RequestUtils

import gololang.JSON
import java.io.{BufferedReader, InputStreamReader, IOException}
import java.util.stream.Collectors

let USER_AGENT = _createUserAgent()
let DEFAULT_TIMEOUT_SECONDS = 10
let DEFAULT_ENCODING = "utf-8"

local function _createUserAgent = {
	let appMetadata = getAppMetaData()
	return appMetadata: appName() + "/" + appMetadata: appVersion()
}

function createHttpRequestFactory = -> createHttpRequestFactory(DEFAULT_ENCODING, DEFAULT_TIMEOUT_SECONDS, map[])

function createHttpRequestFactory = |encoding, timeout| -> createHttpRequestFactory(encoding, timeout, map[])

function createHttpRequestFactory = |encoding, timeout, customProperties| {
	let httpRequestFactory = DynamicObject("HttpRequestFactory"):
		define("encoding", encoding):
		define("timeout", timeout):
		define("customProperties", customProperties):
		define("createHttpRequest", |this| -> createHttpRequest(this: encoding(), this: timeout(), this: customProperties()))
	
	return httpRequestFactory
}

local function createGetProperties = |accept, encoding, customProperties| {
	let properties = map[["Accept", accept], ["Accept-Charset", encoding], ["Cache-Control", "no-cache"], ["User-Agent", USER_AGENT]]
	customProperties: entrySet(): each(|e| -> properties: put(e: key(), e: value()))
	return properties
}

local function createPostProperties = |accept, encoding, contentType, customProperties| {
	let properties = map[["Accept", accept], ["Accept-Charset", encoding], ["Cache-Control", "no-cache"], ["Content-Type", contentType], ["User-Agent", USER_AGENT]]
	customProperties: entrySet(): each(|e| -> properties: put(e: key(), e: value()))
	return properties
}

local function createHttpRequest = |encoding, timeout, customProperties| {
	let httpRequest = DynamicObject("HttpRequest"):
		define("_timeout", timeout):
		define("_encoding", encoding):
		define("_customProperties", customProperties):
		define("doHttpGetRequestAndReturnJSON", |this, url| -> doHttpGetRequestAndReturnJSON(url, this: _encoding(), this: _timeout(), this: _customProperties())):
		define("doHttpPostRequestAndReturnJSON", |this, url, contentType, outputCallback| -> doHttpPostRequestAndReturnJSON(url, this: _encoding(), this: _timeout(), outputCallback, contentType, this: _customProperties())):
		define("doHttpGetRequestAndReturnAsText", |this, url| -> doHttpGetRequestAndReturnAsText(url, this: _encoding(), this: _timeout(), createGetProperties("text/plain", this: _encoding(), this: _customProperties()))):
		define("doHttpPostRequestAndReturnAsText", |this, url, outputCallback, contentType| -> doHttpPostRequestAndReturnAsText(url, this: _encoding(), createPostProperties("text/plain", this: _encoding(), contentType, this: _customProperties()), this: _timeout(), outputCallback)):
		define("doHttpGetRequest", |this, url, accept, inputHandler | -> doHttpGetRequest(url, this: _timeout(), createGetProperties(accept, this: _encoding(), this: _customProperties()), inputHandler)):
		define("doHttpPostRequest", |this, url, accept, contentType, outputHandler, inputHandler | -> doHttpPostRequest(url, this: _timeout(), createPostProperties(accept, this: _encoding(), contentType, this: _customProperties()), outputHandler, inputHandler))
		
	return httpRequest
}

# GET

local function doHttpGetRequestAndReturnJSON = |url, encoding, timeout, customProperties| {
	let jsonString = doHttpGetRequestAndReturnAsText(url, encoding, timeout, createGetProperties("application/json", encoding, customProperties))
	return JSON.parse(jsonString)
}

local function doHttpGetRequestAndReturnAsText = |url, encoding, timeout, requestPropertiesHandler| {
	return doHttpGetRequest(url, timeout, requestPropertiesHandler, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}

# POST

local function doHttpPostRequestAndReturnJSON = |url, encoding, timeout, outputStreamHandlerCallback, contentType, customProperties| {
	let jsonString = doHttpPostRequestAndReturnAsText(url, encoding, createPostProperties("application/json", encoding, contentType, customProperties), timeout, outputStreamHandlerCallback)
	return JSON.parse(jsonString)
}

local function doHttpPostRequestAndReturnAsText = |url, encoding, requestPropertiesHandler, timeout, outputStreamHandlerCallback| {
	return doHttpPostRequest(url, timeout, requestPropertiesHandler, outputStreamHandlerCallback, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}