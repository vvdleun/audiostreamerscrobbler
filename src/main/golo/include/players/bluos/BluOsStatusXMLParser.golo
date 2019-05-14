module audiostreamerscrobbler.players.bluos.BluOsStatusXMLParser

import nl.vincentvanderleun.scrobbler.bluos.BluOsStatusXMLParserImpl

struct BluOsStatus = {
	success,
	etag,
	album,
	artist,
	name,
	state,
	secs,
	service,
	totlen
}

function createBluOsStatusXMLParser = {
	let bluOsStatusParser = BluOsStatusXMLParserImpl()

	let parser = DynamicObject("BluOsStatusXMLParser"):
		define("_bluOsStatusParser", bluOsStatusParser):
		define("parse", |this, inputStream| -> parseBluOsStatusXML(this, inputStream))
	
	return parser
}

local function parseBluOsStatusXML = |parser, inputStream| {
	let bluOsStatusParser = parser: _bluOsStatusParser()

	let parsedStatus = bluOsStatusParser: parse(inputStream)

	return BluOsStatus(
		parsedStatus: success(),
		parsedStatus: etag(),
		parsedStatus: album(),
		parsedStatus: artist(),
		parsedStatus: name(),
		parsedStatus: state(),
		parsedStatus: secs(),
		parsedStatus: service(),
		parsedStatus: totlen())
	}

