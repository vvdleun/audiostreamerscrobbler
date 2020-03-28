package nl.vincentvanderleun.utils;

import org.xml.sax.Attributes;

import nl.vincentvanderleun.utils.SimpleXMLParserEvents;

@FunctionalInterface
public interface SimpleXMLParserCallback {
	public void onEvent(SimpleXMLParserEvents event, String path, Attributes attributes, String characters);
}

