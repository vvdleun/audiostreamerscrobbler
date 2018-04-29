module audiostreamerscrobbler.utils.SimpleXMLParser

import gololang.Adapters
import javax.xml.parsers.SAXParserFactory

union events = {
	StartElement = { path, attributes }
	EndElement = { path, characters }
}

function parseXmlElements = |inputStream, cb| {
	let factory = SAXParserFactory.newInstance()
	let parser = factory: newSAXParser()
	
	let mutableState = DynamicObject():
		define("path", list[]):
		define("characters", StringBuilder())

	let xmlHandlerAdapter = Adapter():
		extends("org.xml.sax.helpers.DefaultHandler"):
		implements("startElement", |this, uri, localName, qName, attributes| {
			mutableState: path(): add(qName)
			mutableState: characters(StringBuilder())
			cb(events.StartElement(mutableState: path(): join("/"), attributes))
		}):		
		implements("characters", |this, ch, start, length| {
			let s = String(ch, start, length)
			mutableState: characters(): append(s)			
		}):
		implements("endElement", |this, uri, localName, qName| {
			let charactersString = match {
				when mutableState: characters() isnt null then mutableState: characters(): toString()
				otherwise null
			}
			cb(events.EndElement(mutableState: path(): join("/"), charactersString))
			
			mutableState: path(): removeAt(mutableState: path(): size() - 1)
			mutableState: characters(null)
		})

	let statusXMLHandler = xmlHandlerAdapter: newInstance()
	parser: parse(inputStream, statusXMLHandler)
}