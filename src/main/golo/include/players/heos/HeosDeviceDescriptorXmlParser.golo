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

function parseHeosDeviceDescriptorXML = |inputStream| {
	let heosXml = map[]

	parseXmlElements(inputStream, |event| {
		let path = event: path()

		if event: isEndElement() {
			let key = XML_ELEMENTS_TO_KEYS: get(path)
			if key != null {
				heosXml: put(key, event: characters())
			}
		}
	})
	
	return convertToDeviceDescriptor(heosXml)
}

local function convertToDeviceDescriptor = |heosXml| {
	return HeosDeviceDescriptor(
		heosXml: get("deviceType"),
		heosXml: get("friendlyName"),
		heosXml: get("manufacturer")		
	)
}