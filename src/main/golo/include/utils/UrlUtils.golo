module audiostreamerscrobbler.utils.UrlUtils

function createFormattedUrl = |url, path| {
	let formattedUrl = StringBuilder()

	formattedUrl: append(createFormattedUrl(url))

	if (path: startsWith("/")) {
		formattedUrl: append(path: substring(1))
	} else {
		formattedUrl: append(path)
	}

	if (not path: endsWith("/")) {
		formattedUrl: append("/")
	}

	return formattedUrl: toString()
}

function createFormattedUrl = |url| {
	let formattedUrl = StringBuilder()
	if ((not url: startsWith("http://")) and (not url: startsWith("https://"))) {
		formattedUrl: append("http://")
	}
	formattedUrl: append(url)
	if (not url: endsWith("/")) {
		formattedUrl: append("/")
	}

	return formattedUrl: toString()
}