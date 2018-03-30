module audiostreamerscrobbler.utils.RequestUtils

import nl.vincentvanderleun.utils.exceptions.HttpRequestException

import java.io.{BufferedReader, InputStreamReader, IOException}
import java.net.HttpURLConnection
import java.net.URL
import java.util.stream.Collectors

let USER_AGENT = "AudiostreamerScrobbler/0.1"
let DEFAULT_TIMEOUT_SECONDS = 10
let DEFAULT_ENCODING = "utf-8"

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