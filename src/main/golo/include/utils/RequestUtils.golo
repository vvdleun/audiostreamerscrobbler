module audiostreamerscrobbler.utils.RequestUtils

import nl.vincentvanderleun.utils.exceptions.HttpRequestException

import java.io.{BufferedReader, InputStreamReader, IOException}
import java.net.HttpURLConnection
import java.net.URL
import java.util.stream.Collectors

let USER_AGENT = "AudiostreamerScrobbler/v1"

function doHttpGetRequestAndReturnAsText = |url| {
	return doHttpGetRequestAndReturnAsText(url, "UTF-8")
}

function doHttpGetRequestAndReturnAsText = |url, encoding| {
	return doHttpGetRequest(url, |i| {
		 let reader = BufferedReader(InputStreamReader(i, encoding))
		 return reader: lines(): collect(Collectors.joining("\n"))
	})
}

function doHttpGetRequest = |url, inputStreamHandlerCallback| {
	let conn = URL(url): openConnection()
	conn: setRequestMethod("GET")
	conn: setRequestProperty("User-Agent", USER_AGENT)
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