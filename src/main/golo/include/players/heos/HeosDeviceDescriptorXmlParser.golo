module audiostreamerscrobbler.players.heos.HeosDeviceDescriptorXmlParser

import audiostreamerscrobbler.utils.SimpleXMLParser

let XML_ELEMENTS_TO_KEYS = map[
	["root/device/deviceType", "deviceType"],
	["root/device/friendlyName", "friendlyName"],
	["root/device/manufacturer", "manufacturer"]
]

struct HeosDeviceDescriptor = {
	deviceType,
	name,
	manufacturer
}

function createHeosDeviceDescriptorXMLParser = {
	let xmlParser = createSimpleXMLParser()

	let parser = DynamicObject("HeosDeviceDescriptorXMLParser"):
		define("_xmlParser", xmlParser):
		define("parse", |this, inputStream| -> parseHeosDeviceDescriptorXML(this, inputStream))

	return parser
}

function parseHeosDeviceDescriptorXML = |parser, inputStream| {
	let heosXml = map[]

	let xmlParser = parser: _xmlParser()

	xmlParser: parse(inputStream, |event| {
		if event: isEndElement() {
			let path = event: path()
			let key = XML_ELEMENTS_TO_KEYS: get(path)
			if key != null {
				heosXml: put(key, event: characters())
			}
		}
	})

	if (heosXml: isEmpty()) {
		return null
	}

	return convertToDeviceDescriptor(heosXml)
}

local function convertToDeviceDescriptor = |heosXml| {
	return HeosDeviceDescriptor(
		heosXml: get("deviceType"),
		heosXml: get("friendlyName"),
		heosXml: get("manufacturer")		
	)
}