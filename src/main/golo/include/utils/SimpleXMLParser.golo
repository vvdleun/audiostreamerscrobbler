module audiostreamerscrobbler.utils.SimpleXMLParser

import nl.vincentvanderleun.utils.SimpleXMLParser
import nl.vincentvanderleun.utils.SimpleXMLParserCallback

import gololang.Adapters
import javax.xml.parsers.SAXParserFactory

union events = {
	StartElement = { path, attributes }
	EndElement = { path, characters }
}

function createSimpleXMLParser = {
	let xmlParser = SimpleXMLParser()

	let parser = DynamicObject("SimpleXMLParser"):
		define("_xmlParser", xmlParser):
		define("parse", |this, inputStream, cb| -> parseXmlElements(this, inputStream, cb))

	return parser
}

local function parseXmlElements = |parser, inputStream, cb| {
	let xmlParser = parser: _xmlParser()
	
	let simpleXmlCb = asFunctionalInterface(nl.vincentvanderleun.utils.SimpleXMLParserCallback.class, |event, path, attributes, characters| {
		# Convert event to events union defined above and call specified callback
		case {
			when event: name() == "START_ELEMENT" {
				cb(events.StartElement(path, attributes))
			}
			when event: name() == "END_ELEMENT" {
				cb(events.EndElement(path, characters))
			}
			otherwise {
				raise("Internal error: unknown event returned by SimpleXMLParser implementation: '" + event + "'")
			}
		}
	})
	
	xmlParser: parse(inputStream, simpleXmlCb)
}
