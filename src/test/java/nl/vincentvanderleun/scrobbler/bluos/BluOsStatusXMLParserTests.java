package nl.vincentvanderleun.scrobbler.bluos;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.ByteArrayInputStream;
import java.io.IOException;

import org.junit.Before;
import org.junit.Test;

public class BluOsStatusXMLParserTests {
	private BluOsStatusXMLParser bluOsStatusXMLParser;

	String BLUOS_STATUS_XML_DATA = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\r\n" + 
			"<status etag=\"7f41bde69dfcfd2dcbfd8dd90750cb37\">\r\n" + 
			"<album>The Voice Of Love</album>\r\n" + 
			"<artist>Julee Cruise</artist>\r\n" + 
			"<canMovePlayback>true</canMovePlayback>\r\n" + 
			"<canSeek>1</canSeek>\r\n" + 
			"<cursor>1439</cursor>\r\n" + 
			"<fn>Tidal:3469120</fn>\r\n" + 
			"<image>/Artwork?service=Tidal&amp;songid=Tidal%3ACENSORED</image>\r\n" +
			"<indexing>0</indexing>\r\n" + 
			"<mid>1</mid>\r\n" + 
			"<mode>1</mode>\r\n" + 
			"<name>She Would Die For Love</name>\r\n" + 
			"<pid>378</pid>\r\n" + 
			"<prid>0</prid>\r\n" + 
			"<quality>cd</quality>\r\n" + 
			"<repeat>2</repeat>\r\n" + 
			"<service>Tidal</service>\r\n" + 
			"<serviceIcon>/Sources/images/TidalIcon.png</serviceIcon>\r\n" + 
			"<shuffle>0</shuffle>\r\n" + 
			"<sid>8</sid>\r\n" + 
			"<sleep></sleep>\r\n" + 
			"<song>1436</song>\r\n" + 
			"<state>play</state>\r\n" + 
			"<streamFormat>FLAC 44100/16/2</streamFormat>\r\n" + 
			"<syncStat>1574</syncStat>\r\n" + 
			"<title1>She Would Die For Love</title1>\r\n" + 
			"<title2>Julee Cruise</title2>\r\n" + 
			"<title3>The Voice Of Love</title3>\r\n" + 
			"<totlen>366</totlen>\r\n" + 
			"<volume>39</volume>\r\n" + 
			"<secs>54</secs>\r\n" + 
			"</status>";
	
	@Before
	public void init() {
		bluOsStatusXMLParser = new BluOsStatusXMLParser();
	}
	
	@Test
	public void mustParseBluOsStatusXML() throws IOException {
		ByteArrayInputStream inputStream = new ByteArrayInputStream(BLUOS_STATUS_XML_DATA.getBytes());

		BluOsParsedStatus status = bluOsStatusXMLParser.parse(inputStream);

		assertEquals("The Voice Of Love", status.getAlbum());
		assertEquals("Julee Cruise", status.getArtist());
		assertEquals("7f41bde69dfcfd2dcbfd8dd90750cb37", status.getEtag());
		assertEquals("She Would Die For Love", status.getName());
		assertEquals(54, status.getSecs());
		assertEquals("Tidal", status.getService());
		assertEquals("play", status.getState());
		assertEquals(366, status.getTotlen());
		assertTrue(status.isSuccess());
	}
}
