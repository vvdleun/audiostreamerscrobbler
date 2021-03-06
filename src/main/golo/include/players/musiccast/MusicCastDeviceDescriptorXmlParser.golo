module audiostreamerscrobbler.players.musiccast.MusicCastDeviceDescriptorXmlParser

import audiostreamerscrobbler.utils.SimpleXMLParser

let XML_YAMAHA_X_PATH = "root/yamaha:X_device"
let XML_YAMAHA_X_SERVICE_PATH = XML_YAMAHA_X_PATH + "/yamaha:X_serviceList/yamaha:X_service"
let XML_YAMAHA_X_SPEC_TYPE_PATH = XML_YAMAHA_X_SERVICE_PATH + "/yamaha:X_specType"
let XML_YAMAHA_X_CONTROL_URL_PATH = XML_YAMAHA_X_SERVICE_PATH + "/yamaha:X_yxcControlURL"

let XML_SPEC_TYPE_EXTENDED_CONTOL = "urn:schemas-yamaha-com:service:X_YamahaExtendedControl:1"

let XML_ELEMENTS_TO_KEYS = map[
	["root/device/manufacturer", "manufacturer"],
	["root/device/modelName", "model"],
	["root/device/friendlyName", "name"],
	["root/device/presentationURL", "host"],
	["root/yamaha:X_device/yamaha:X_URLBase", "urlBase"]]

struct MusicCastDeviceDescriptor = {
	hasRequiredElement,
	manufacturer,
	model,
	name,
	host,
	urlBase,
	yxcControlUrl
}

function createMusicCastDeviceDescriptorParser = {
	let xmlParser = createSimpleXMLParser()

	let parser = DynamicObject("MusicCastDeviceDescriptorParser"):
		define("_xmlParser", xmlParser):
		define("parse", |this, inputStream| -> parseMusicCastDeviceDescriptorXML(this, inputStream))

	return parser
}

local function parseMusicCastDeviceDescriptorXML = |parser, inputStream| {
	let musicCastXml = map[]
	let service = map[["isService", false]]

	parseMusicCastDeviceDescriptorXML(parser, inputStream, musicCastXml, service)

	return convertToDeviceDescriptor(musicCastXml)
}

local function parseMusicCastDeviceDescriptorXML = |parser, inputStream, musicCastXml, service| {
	let xmlParser = parser: _xmlParser()

	xmlParser: parse(inputStream, |event| {
		let path = event: path()

		if event: isStartElement() {
			if (path == XML_YAMAHA_X_PATH) {
				# MusicCast specs asks to validate explicitly that this element exists
				musicCastXml: put("hasRequiredElement", true)
			} else if (path == XML_YAMAHA_X_SERVICE_PATH) {
				# Sub elements are parsed in the temporary "service" map
				service: put("isService", true)
			}
		} else if event: isEndElement() {
			if (path == XML_YAMAHA_X_SERVICE_PATH) {
				# Check whether this service was the one we were looking for
				if (service: get(XML_YAMAHA_X_SPEC_TYPE_PATH) == XML_SPEC_TYPE_EXTENDED_CONTOL) {
					musicCastXml: put("yxcControlUrl", service: get(XML_YAMAHA_X_CONTROL_URL_PATH))
				}
				service: clear()
				service: put("isService", false)

			} else if (service: get("isService")) {
				# Store sub elements of <yamaha:X_service> element in temporary "service" map
				service: put(path, event: characters())

			} else {
				# Map simple fields that need no additional parsing logic
				let key = XML_ELEMENTS_TO_KEYS: get(path)
				if key != null {
					musicCastXml: put(key, event: characters())
				}
			}
		}
	})
}

local function convertToDeviceDescriptor = |musicCastXml| {
	return MusicCastDeviceDescriptor(
		musicCastXml: get("hasRequiredElement"),
		musicCastXml: get("manufacturer"),
		musicCastXml: get("model"),
		musicCastXml: get("name"),
		musicCastXml: get("host"),
		musicCastXml: get("urlBase"),
		musicCastXml: get("yxcControlUrl"))
}