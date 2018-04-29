package audiostreamerscrobbler.players.bluos;

import audiostreamerscrobbler.players.bluos.BluOsStatusXMLParser;
import gololang.GoloStruct;

import static org.junit.Assert.*;

import java.io.ByteArrayInputStream;
import java.io.InputStream;

import org.junit.Test;

public class BluOsStatusXMLParserTest {
	private final static String TIDAL_PLAY_XML = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\r\n" + 
			"<status etag=\"e147e1389c13ace6e4b0e541632ea2dc\">\r\n" + 
			"<album>Disparition</album>\r\n" + 
			"<artist>Sällskapet</artist>\r\n" + 
			"<canMovePlayback>true</canMovePlayback>\r\n" + 
			"<canSeek>1</canSeek>\r\n" + 
			"<cursor>238</cursor>\r\n" + 
			"<fn>Tidal:85500487</fn>\r\n" + 
			"<image>/Artwork?service=Tidal&amp;songid=Tidal%3A85500487</image>\r\n" + 
			"<indexing>0</indexing>\r\n" + 
			"<mid>11</mid>\r\n" + 
			"<mode>1</mode>\r\n" + 
			"<name>Disparition, Pt. 1 (feat. Andrea Schroeder)</name>\r\n" + 
			"<pid>2439</pid>\r\n" + 
			"<prid>0</prid>\r\n" + 
			"<quality>cd</quality>\r\n" + 
			"<repeat>2</repeat>\r\n" + 
			"<service>Tidal</service>\r\n" + 
			"<serviceIcon>Sources/images/TidalIcon.png</serviceIcon>\r\n" + 
			"<shuffle>0</shuffle>\r\n" + 
			"<sid>3</sid>\r\n" + 
			"<sleep></sleep>\r\n" + 
			"<song>230</song>\r\n" + 
			"<state>play</state>\r\n" + 
			"<streamFormat>FLAC 44100/16/2</streamFormat>\r\n" + 
			"<syncStat>21</syncStat>\r\n" + 
			"<title1>Disparition, Pt. 1 (feat. Andrea Schroeder)</title1>\r\n" + 
			"<title2>Sällskapet</title2>\r\n" + 
			"<title3>Disparition</title3>\r\n" + 
			"<totlen>237</totlen>\r\n" + 
			"<volume>50</volume>\r\n" + 
			"<secs>115</secs>\r\n" + 
			"</status>";
	
	@Test
	public void mustParseTidalPlayStatusXML() throws Exception {
		GoloStruct song = (GoloStruct)BluOsStatusXMLParser.parseBluOsStatusXML(getInputStreamOfString(TIDAL_PLAY_XML));
		assertEquals(true, song.get("success"));
		assertEquals("e147e1389c13ace6e4b0e541632ea2dc", song.get("etag"));
		assertEquals("Disparition", song.get("album"));
		assertEquals("Sällskapet", song.get("artist"));
		assertEquals("Disparition, Pt. 1 (feat. Andrea Schroeder)", song.get("name"));
		assertEquals("play", song.get("state"));
		assertEquals("115", song.get("secs"));
		assertEquals("Tidal", song.get("service"));
		assertEquals("237", song.get("totlen"));
	}

	private static final String LOCAL_PLAY_XML = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\r\n" + 
			"<status etag=\"96d92a5e5dec1604475d6297b1b2de4a\">\r\n" + 
			"<album>Strangers</album>\r\n" + 
			"<artist>Marissa Nadler</artist>\r\n" + 
			"<autofill>240</autofill>\r\n" + 
			"<canMovePlayback>true</canMovePlayback>\r\n" + 
			"<canSeek>1</canSeek>\r\n" + 
			"<cursor>245</cursor>\r\n" + 
			"<fn>/var/mnt/NAS-Music/FLAC/Marissa Nadler/Strangers/Marissa Nadler - Strangers - 05 All the Colors of the Dark.flac</fn>\r\n" + 
			"<image>/Artwork?service=LocalMusic&amp;fn=%2Fvar%2Fmnt%2FWDMYCLOUD-Music%2FFLAC%2FMarissa%20Nadler%2FStrangers%2FMarissa%20Nadler%20-%20Strangers%20-%2005%20All%20the%20Colors%20of%20the%20Dark.flac</image>\r\n" + 
			"<indexing>0</indexing>\r\n" + 
			"<mid>11</mid>\r\n" + 
			"<mode>1</mode>\r\n" + 
			"<name>All the Colors of the Dark</name>\r\n" + 
			"<pid>2440</pid>\r\n" + 
			"<prid>0</prid>\r\n" + 
			"<quality>cd</quality>\r\n" + 
			"<repeat>2</repeat>\r\n" + 
			"<service>LocalMusic</service>\r\n" + 
			"<shuffle>0</shuffle>\r\n" + 
			"<sid>3</sid>\r\n" + 
			"<sleep></sleep>\r\n" + 
			"<song>239</song>\r\n" + 
			"<state>play</state>\r\n" + 
			"<syncStat>21</syncStat>\r\n" + 
			"<title1>All the Colors of the Dark</title1>\r\n" + 
			"<title2>Marissa Nadler</title2>\r\n" + 
			"<title3>Strangers</title3>\r\n" + 
			"<totlen>253</totlen>\r\n" + 
			"<volume>50</volume>\r\n" + 
			"<secs>41</secs>\r\n" + 
			"</status>";

	@Test
	public void mustParseLocalPlayStatusXML() throws Exception {
		GoloStruct song = (GoloStruct)BluOsStatusXMLParser.parseBluOsStatusXML(getInputStreamOfString(LOCAL_PLAY_XML));
		assertEquals(true, song.get("success"));
		assertEquals("96d92a5e5dec1604475d6297b1b2de4a", song.get("etag"));
		assertEquals("Strangers", song.get("album"));
		assertEquals("Marissa Nadler", song.get("artist"));
		assertEquals("All the Colors of the Dark", song.get("name"));
		assertEquals("play", song.get("state"));
		assertEquals("41", song.get("secs"));
		assertEquals("LocalMusic", song.get("service"));
		assertEquals("253", song.get("totlen"));
	}

	private static final String TUNE_IN_XML = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\r\n" + 
			"<status etag=\"6572ca9beee7c0bfa528cf75f013aeee\">\r\n" + 
			"<autofill>241</autofill>\r\n" + 
			"<canMovePlayback>true</canMovePlayback>\r\n" + 
			"<canSeek>0</canSeek>\r\n" + 
			"<currentImage>http://cdn-radiotime-logos.tunein.com/s225199q.png</currentImage>\r\n" + 
			"<cursor>245</cursor>\r\n" + 
			"<image>http://cdn-radiotime-logos.tunein.com/s225199q.png</image>\r\n" + 
			"<indexing>0</indexing>\r\n" + 
			"<mid>11</mid>\r\n" + 
			"<mode>1</mode>\r\n" + 
			"<pid>2440</pid>\r\n" + 
			"<preset_id>s225199</preset_id>\r\n" + 
			"<preset_name>Jazz London Radio</preset_name>\r\n" + 
			"<prid>0</prid>\r\n" + 
			"<quality>208000</quality>\r\n" + 
			"<repeat>2</repeat>\r\n" + 
			"<service>TuneIn</service>\r\n" + 
			"<serviceIcon>Sources/images/TuneInIcon.png</serviceIcon>\r\n" + 
			"<shuffle>0</shuffle>\r\n" + 
			"<sid>3</sid>\r\n" + 
			"<sleep></sleep>\r\n" + 
			"<song>0</song>\r\n" + 
			"<state>stream</state>\r\n" + 
			"<stationImage>http://cdn-radiotime-logos.tunein.com/s225199q.png</stationImage>\r\n" + 
			"<streamFormat>AAC 208 kb/s</streamFormat>\r\n" + 
			"<streamUrl>TuneIn:s225199/http://opml.radiotime.com/Tune.ashx?id=s225199&amp;formats=wma,mp3,aac,ogg,hls&amp;partnerId=8OeGua6y&amp;serial=68:94:23:E6:72:5B</streamUrl>\r\n" + 
			"<syncStat>21</syncStat>\r\n" + 
			"<title1>Classic Jazz</title1>\r\n" + 
			"<title2>Sam Braysher with Michael Kanan - Golden Eaarings</title2>\r\n" + 
			"<title3>Jazz London Radio</title3>\r\n" + 
			"<totlen>7200</totlen>\r\n" + 
			"<volume>50</volume>\r\n" + 
			"<secs>1406</secs>\r\n" + 
			"</status>";
	
	@Test
	public void mustParseTuneInPlayStatusXML() throws Exception {
		GoloStruct song = (GoloStruct)BluOsStatusXMLParser.parseBluOsStatusXML(getInputStreamOfString(TUNE_IN_XML));
		assertEquals(true, song.get("success"));
		assertEquals("6572ca9beee7c0bfa528cf75f013aeee", song.get("etag"));
		assertNull(song.get("album"));
		assertNull(song.get("artist"));
		assertNull(song.get("name"));
		assertEquals("stream", song.get("state"));
		assertEquals("1406", song.get("secs"));
		assertEquals("TuneIn", song.get("service"));
		assertEquals("7200", song.get("totlen"));
	}

	private static final String RADIO_PARADISE_XML = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\r\n" + 
			"<status etag=\"8a4b1a4bc0b51ba83857f927e2c8d6a4\">\r\n" + 
			"<actions>\r\n" + 
			"  <action name=\"back\" />\r\n" + 
			"</actions>\r\n" + 
			"<album>The Cost</album>\r\n" + 
			"<artist>The Frames</artist>\r\n" + 
			"<autofill>241</autofill>\r\n" + 
			"<canMovePlayback>true</canMovePlayback>\r\n" + 
			"<canSeek>0</canSeek>\r\n" + 
			"<currentImage>https://img.radioparadise.com/covers/l/B000JGF1BI.jpg</currentImage>\r\n" + 
			"<cursor>245</cursor>\r\n" + 
			"<image>https://img.radioparadise.com/covers/l/B000JGF1BI.jpg</image>\r\n" + 
			"<indexing>0</indexing>\r\n" + 
			"<lyricsid>39474</lyricsid>\r\n" + 
			"<mid>11</mid>\r\n" + 
			"<mode>1</mode>\r\n" + 
			"<pid>2440</pid>\r\n" + 
			"<prid>0</prid>\r\n" + 
			"<quality>352000</quality>\r\n" + 
			"<repeat>2</repeat>\r\n" + 
			"<service>RadioParadise</service>\r\n" + 
			"<serviceIcon>/Sources/images/ParadiseRadioIcon.png</serviceIcon>\r\n" + 
			"<shuffle>0</shuffle>\r\n" + 
			"<sid>3</sid>\r\n" + 
			"<sleep></sleep>\r\n" + 
			"<song>0</song>\r\n" + 
			"<state>stream</state>\r\n" + 
			"<stationImage>/Sources/images/ParadiseRadioIcon.png</stationImage>\r\n" + 
			"<streamFormat>AAC 352 kb/s</streamFormat>\r\n" + 
			"<streamUrl>RadioParadise:http://stream-tx3.radioparadise.com/aac-320</streamUrl>\r\n" + 
			"<syncStat>21</syncStat>\r\n" + 
			"<title1>Radio Paradise</title1>\r\n" + 
			"<title2>Rise</title2>\r\n" + 
			"<title3>The Frames • The Cost</title3>\r\n" + 
			"<volume>50</volume>\r\n" + 
			"<secs>16</secs>\r\n" + 
			"</status>";

	@Test
	public void mustParseRadioParadisePlayStatusXML() throws Exception {
		GoloStruct song = (GoloStruct)BluOsStatusXMLParser.parseBluOsStatusXML(getInputStreamOfString(RADIO_PARADISE_XML));
		assertEquals(true, song.get("success"));
		assertEquals("8a4b1a4bc0b51ba83857f927e2c8d6a4", song.get("etag"));
		assertEquals("The Cost", song.get("album"));
		assertEquals("The Frames", song.get("artist"));
		assertNull(song.get("name"));
		assertEquals("stream", song.get("state"));
		assertEquals("16", song.get("secs"));
		assertEquals("RadioParadise", song.get("service"));
		assertNull(song.get("totlen"));
	}
	
	private InputStream getInputStreamOfString(String input) throws Exception {
		return new ByteArrayInputStream(input.getBytes("UTF-8"));
	}
}
