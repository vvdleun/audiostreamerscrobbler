package nl.vincentvanderleun.utils;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

public class SimpleXMLParserImpl {
	private final SAXParser saxParser;
	
	public SimpleXMLParserImpl() {
		try {
			SAXParserFactory parserFactory = SAXParserFactory.newInstance();
			this.saxParser = parserFactory.newSAXParser();
		} catch(SAXException | ParserConfigurationException ex) {
			throw new RuntimeException(ex);
		}
	}

	public void parse(InputStream inputStream, SimpleXMLParserCallback callback) throws IOException {
		try {
			XMLParserHandler xmlParserHandler = new XMLParserHandler(callback);
			this.saxParser.parse(inputStream, xmlParserHandler);
		} catch(SAXException ex) {
			throw new IOException(ex);
		}
	}
	
	private static class XMLParserHandler extends DefaultHandler {
		private final MutableData parsedData = new MutableData();
		private final SimpleXMLParserCallback callback;
		
		public XMLParserHandler(SimpleXMLParserCallback callback) {
			this.callback = callback;
		}
		
		@Override
		public void startDocument() throws SAXException {
			parsedData.reset();
		}

		@Override
		public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
			parsedData.path.add(qName);
			parsedData.characters = new StringBuilder();

			String joinedPath = String.join("/", parsedData.path);

			callback.onEvent(SimpleXMLParserEvents.START_ELEMENT, joinedPath, attributes, null);
		}
		
		@Override
		public void characters(char[] ch, int start, int length) throws SAXException {
			if (parsedData.characters != null) {
				parsedData.characters.append(ch, start, length);
			}
		}

		@Override
		public void endElement(String uri, String localName, String qName) throws SAXException {
			String characters = parsedData.characters != null ? parsedData.characters.toString() : null;

			String joinedPath = String.join("/", parsedData.path);
			
			callback.onEvent(SimpleXMLParserEvents.END_ELEMENT, joinedPath, null, characters);

			parsedData.path.remove(parsedData.path.size() - 1);
			parsedData.characters = null;
		}
	}
	
	private static class MutableData {
		public List<String> path;
		public StringBuilder characters;

		public MutableData() {
			reset();
		}
		
		public void reset() {
			path = new ArrayList<>();
			characters = new StringBuilder();
		}
	}
}
