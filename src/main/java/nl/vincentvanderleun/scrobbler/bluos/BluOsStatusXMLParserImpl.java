package nl.vincentvanderleun.scrobbler.bluos;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

public class BluOsStatusXMLParserImpl {
	private static final Set<String> STATUS_XML_ELEMENTS = new HashSet<>();

	private final SAXParser saxParser;
	private final BluOsStatusXmlHandler xmlHandler = new BluOsStatusXmlHandler();

	static {
		STATUS_XML_ELEMENTS.add("album");
		STATUS_XML_ELEMENTS.add("artist");
		STATUS_XML_ELEMENTS.add("name");
		STATUS_XML_ELEMENTS.add("state");
		STATUS_XML_ELEMENTS.add("secs");
		STATUS_XML_ELEMENTS.add("service");
		STATUS_XML_ELEMENTS.add("totlen");
	}
	
	public BluOsStatusXMLParserImpl() {
		try {
			SAXParserFactory factory = SAXParserFactory.newInstance();
			saxParser = factory.newSAXParser();
		} catch (SAXException | ParserConfigurationException ex) {
			throw new RuntimeException(ex);
		}
	}
	
	public BluOsParsedStatus parse(InputStream inputStream) throws IOException {
		try {
			saxParser.parse(inputStream, xmlHandler);
			
			BluOsParsedStatus bluOsStatus = new BluOsParsedStatus();
			
			bluOsStatus.setAlbum(xmlHandler.parsedData.playerState.get("album"));
			bluOsStatus.setArtist(xmlHandler.parsedData.playerState.get("artist"));
			bluOsStatus.setEtag(xmlHandler.parsedData.etag);
			bluOsStatus.setName(xmlHandler.parsedData.playerState.get("name"));
			if (xmlHandler.parsedData.playerState.get("secs") != null) {
				bluOsStatus.setSecs(Integer.parseInt(xmlHandler.parsedData.playerState.get("secs")));
			}
			bluOsStatus.setService(xmlHandler.parsedData.playerState.get("service"));
			bluOsStatus.setState(xmlHandler.parsedData.playerState.get("state"));
			if (xmlHandler.parsedData.playerState.get("success") != null) {
				bluOsStatus.setSuccess(Boolean.parseBoolean(xmlHandler.parsedData.playerState.get("success")));
			}
			bluOsStatus.setSuccess(xmlHandler.parsedData.isStatus);
			if (xmlHandler.parsedData.playerState.get("totlen") != null) {
				bluOsStatus.setTotlen(Integer.parseInt(xmlHandler.parsedData.playerState.get("totlen")));
			}
			
			return bluOsStatus;
			
		} catch(SAXException ex) {
			throw new IOException(ex);
		}
	}

	private static class BluOsStatusXmlHandler extends DefaultHandler {
		public final MutableData parsedData = new MutableData();
		
		@Override
		public void startDocument() throws SAXException {
			parsedData.reset();
		}

		@Override
		public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
			parsedData.depth++;
			parsedData.elementName = qName;
			parsedData.characters = new StringBuilder();
			
			if (parsedData.depth == 1) {
				if ("status".equals(qName)) {
					parsedData.etag = attributes.getValue("etag");
					parsedData.isStatus = true;
				} else {
					parsedData.isStatus = false;
				}
			}
		}

		@Override
		public void characters(char[] ch, int start, int length) throws SAXException {
			if (parsedData.elementName != null) {
				parsedData.characters.append(ch, start, length);
			}
		}

		@Override
		public void endElement(String uri, String localName, String qName) throws SAXException {
			if (parsedData.isStatus && parsedData.depth == 2 && STATUS_XML_ELEMENTS.contains(qName)) {
				parsedData.playerState.put(qName, parsedData.characters.toString());
			}
			
			parsedData.depth--;
			parsedData.elementName = null;
		}
	}
	
	private static class MutableData {
		public int depth;
		public String elementName;
		public StringBuilder characters;
		public boolean isStatus;
		public String etag;
		public Map<String, String> playerState;
		
		public MutableData() {
			reset();
		}
		
		public void reset() {
			this.depth = 0;
			this.elementName = null;
			this.characters = new StringBuilder();
			this.isStatus = false;
			this.etag = null;
			this.playerState = new HashMap<>();
		}
	}
}
