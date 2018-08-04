module testie

import java.lang.Integer

function main = |args| {
	var i = 0
	while (true) {
		huh(i)
		i = i + 1
	}
}

function huh = |i| {
	let xmlHandlerAdapter = Adapter():
		extends("org.xml.sax.helpers.DefaultHandler"):
		implements("startElement", |this, uri, localName, qName, attributes| {
		}):		
		implements("characters", |this, ch, start, length| {
		}):
		implements("endElement", |this, uri, localName, qName| {
		})

	let test = xmlHandlerAdapter: newInstance()		
	println(i + ") "  test)
}