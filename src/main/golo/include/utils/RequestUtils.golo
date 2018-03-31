module audiostreamerscrobbler.utils.RequestUtils

import nl.vincentvanderleun.utils.exceptions.HttpRequestException

import java.io.{BufferedReader, InputStreamReader, IOException}
import java.net.HttpURLConnection
import java.net.URL
import java.util.stream.Collectors

let USER_AGENT = "AudiostreamerScrobbler/0.1"
let DEFAULT_TIMEOUT_SECONDS = 10
let DEFAULT_ENCODING = "utf-8"

# High level

# JSON

# - GET and return response as JSON

function doHttpGetRequestAndReturnJSON = |url| {
	return doHttpGetRequestAndReturnJSON(url, DEFAULT_TIMEOUT_SECONDS)
}

function doHttpGetRequestAndReturnJSON = |url, timeout| {
	let jsonString = doHttpGetRequestAndReturnAsText(url)
	return JSON.parse(jsonString)
}

# - POST and return response as JSON

function doHttpPostRequestAndReturnJSON = |url, outputStreamHandlerCallback| {
	return doHttpPostRequestAndReturnJSON(url, DEFAULT_ENCODING, DEFAULT_TIMEOUT_SECONDS, outputStreamHandlerCallback)
}

function doHttpPostRequestAndReturnJSON = |url, encoding, timeout, outputStreamHandlerCallback| {
	let jsonString = doHttpPostRequestAndReturnAsText(url, encoding, timeout, outputStreamHandlerCallback)
	return JSON.parse(jsonString)
}

# TEXT

# - GET and return response as Text

function doHttpGetRequestAndReturnAsText = |url| {
	return doHttpGetRequestAndReturnAsText(url, DEFAULT_ENCODING)
}

function doHttpGetRequestAndReturnAsText = |url, encoding| {
	return doHttpGetRequestAndReturnAsText(url, encoding, DEFAULT_TIMEOUT_SECONDS)
}

function doHttpGetRequestAndReturnAsText = |url, encoding, timeout| {
	return doHttpGetRequest(url, timeout, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}

# - POST and return response as Text

function doHttpPostRequestAndReturnAsText = |url, outputStreamHandlerCallback| {
	return doHttpGetRequestAndReturnAsText(url, DEFAULT_ENCODING, DEFAULT_TIMEOUT_SECONDS, outputStreamHandlerCallback)
}

function doHttpPostRequestAndReturnAsText = |url, encoding, timeout, outputStreamHandlerCallback| {
	return doHttpPostRequest(url, timeout, outputStreamHandlerCallback, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}

# CUSTOM

function doHttpGetRequest = |url, inputStreamHandlerCallback| {
	return doHttpGetRequest(url, DEFAULT_TIMEOUT_SECONDS, inputStreamHandlerCallback)
}

function doHttpGetRequest = |url, timeout, inputStreamHandlerCallback| {
	let conn = URL(url): openConnection()

	conn: setRequestMethod("GET")
	conn: setRequestProperty("User-Agent", USER_AGENT)
	conn: setConnectTimeout(timeout * 1000)
	conn: setReadTimeout(timeout * 1000)

	let responseCode = conn: getResponseCode()
	if (responseCode != HttpURLConnection.HTTP_OK()) {
		throw HttpRequestException(responseCode)
	}

	let inputStream = conn: getInputStream()
	try {
		return inputStreamHandlerCallback(inputStream)
	} finally {
		inputStream: close()
	}
}

function doHttpPostRequest = |url, timeout, outputStreamHandlerCallback, inputStreamHandlerCallback| {
	let conn = URL(url): openConnection()

	conn: setRequestMethod("POST")
	conn: setRequestProperty("User-Agent", USER_AGENT)
	conn: setConnectTimeout(timeout * 1000)
	conn: setReadTimeout(timeout * 1000)
	conn: doOutput(true)
	
	let outputStream = conn: getOutputStream()
	try {
		outputStreamHandlerCallback(outputStream)
	} finally {
		outputStream: close()
	}
	
	let responseCode = conn: getResponseCode()
	if (responseCode != HttpURLConnection.HTTP_OK()) {
		throw HttpRequestException(responseCode)
	}

	let inputStream = conn: getInputStream()
	try {
		return inputStreamHandlerCallback(inputStream)
	} finally {
		inputStream: close()
	}
}