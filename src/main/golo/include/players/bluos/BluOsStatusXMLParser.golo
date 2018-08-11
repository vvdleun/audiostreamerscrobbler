module audiostreamerscrobbler.players.bluos.BluOsStatusXMLParser

import gololang.Adapters
import javax.xml.parsers.SAXParserFactory
import org.xml.sax.Attributes
import org.xml.sax.SAXException

let STATUS_XML_ELEMENTS = list["album", "artist", "name", "state", "secs", "service", "totlen"]

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
	let parser = DynamicObject("BluOsStatusXMLParser"):
		define("parse", |this, inputStream| -> parseBluOsStatusXML(inputStream))
	
	return parser
}

local function parseBluOsStatusXML = |inputStream| {
	let factory = SAXParserFactory.newInstance()
	let parser = factory: newSAXParser()

	let mutableState = DynamicObject():
		define("depth", 0):
		define("elementName", null):
		define("characters", StringBuilder()):
		define("isStatus", false):
		define("etag", null):
		define("playerState", map[])

	let xmlHandlerAdapter = Adapter():
		extends("org.xml.sax.helpers.DefaultHandler"):
		implements("startElement", |this, uri, localName, qName, attributes| {
			mutableState: depth(mutableState: depth() + 1)
			mutableState: elementName(qName)
			mutableState: characters(StringBuilder())
			
			if (mutableState: depth() == 1 and qName == "status") {
				mutableState: etag(attributes: getValue("etag"))
			}
		}):		
		implements("characters", |this, ch, start, length| {
			let s = String(ch, start, length)
			mutableState: characters(): append(s)			
		}):
		implements("endElement", |this, uri, localName, qName| {
			let depth = mutableState: depth()

			if (depth == 1 and qName == "status") {
				mutableState: isStatus(true)				
			} else if (depth == 2 and STATUS_XML_ELEMENTS: contains(qName)) {
				mutableState: playerState(): put(qName, mutableState: characters(): toString())
			}
			
			mutableState: depth(depth - 1)
			mutableState: elementName(null)
		})

	let statusXMLHandler = xmlHandlerAdapter: newInstance()
	parser: parse(inputStream, statusXMLHandler)

	return createBluOsSong(mutableState: isStatus(), mutableState: etag(), mutableState: playerState())
}

local function createBluOsSong = |isStatus, etag, playerState| {
	return BluOsStatus(
		isStatus,
		etag,
		playerState: get("album"),
		playerState: get("artist"),
		playerState: get("name"),
		playerState: get("state"),
		playerState: get("secs"),
		playerState: get("service"),
		playerState: get("totlen"))
}