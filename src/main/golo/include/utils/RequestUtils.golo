module audiostreamerscrobbler.utils.RequestUtils

import nl.vincentvanderleun.utils.exceptions.HttpRequestException

import java.net.HttpURLConnection
import java.net.URL

function doHttpGetRequest = |url, timeout, requestProperties, inputStreamHandlerCallback| {
	let conn = URL(url): openConnection()

	conn: setRequestMethod("GET")

	requestProperties: entrySet(): each(|p| -> conn: setRequestProperty(p: key(), p: value()))
	
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

function doHttpPostRequest = |url, timeout, requestProperties, outputStreamHandlerCallback, inputStreamHandlerCallback| {
	let conn = URL(url): openConnection()

	conn: setRequestMethod("POST")

	requestProperties: entrySet(): each(|p| -> conn: setRequestProperty(p: key(), p: value()))
	
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