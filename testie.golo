module xmlMemoryLeakTest

import gololang.Adapters
import java.io.ByteArrayInputStream
import javax.xml.parsers.SAXParserFactory

let TEST_XML = """<?xml version="1.0" encoding="UTF-8"?><note><text>Random XML example</text></note>"""

function main = |args| {
    let parser = SAXParserFactory.newInstance(): newSAXParser()

    let xmlHandlerAdapter = Adapter():
        extends("org.xml.sax.helpers.DefaultHandler")
	
    while (true) {
        let inputStream = ByteArrayInputStream(TEST_XML: getBytes())

		let xmlHandler = xmlHandlerAdapter: newInstance()
		parser: parse(inputStream, xmlHandler)

        inputStream: close()
    }
}