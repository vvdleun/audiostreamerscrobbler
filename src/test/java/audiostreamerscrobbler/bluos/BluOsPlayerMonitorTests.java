package audiostreamerscrobbler.bluos;

import static java.lang.invoke.MethodType.genericMethodType;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.lang.invoke.MethodHandle;
import java.util.ArrayList;
import java.util.List;

import org.junit.Before;
import org.junit.Test;

import audiostreamerscrobbler.mocks.MockedBluOsPlayerImpl;
import audiostreamerscrobbler.mocks.MockedHttpRequestFactory;
import gololang.DynamicObject;
import gololang.GoloStruct;
import gololang.Tuple;
import gololang.Union;

public class BluOsPlayerMonitorTests {
	private MockedHttpRequestFactory httpRequestFactory;
	private DynamicObject blueOsPlayerMonitor;
	private MethodHandle monitorPlayerInvoker;

	@Before
	public void setup() {
		MockedBluOsPlayerImpl bluOsImpl = new MockedBluOsPlayerImpl("Name", "Port", "Model", "Version", "MacAddress", "IpAddress", "LSDPVersion", "Host");
		DynamicObject bluosPlayer = (DynamicObject)BluOsPlayer.createBluOsPlayerImpl(bluOsImpl);
		httpRequestFactory = new MockedHttpRequestFactory();
		blueOsPlayerMonitor = (DynamicObject)BluOsPlayerMonitor.createBluOsPlayerMonitor(bluosPlayer, httpRequestFactory);
		monitorPlayerInvoker = blueOsPlayerMonitor.invoker("monitorPlayer", genericMethodType(1));
	}
	
	private static final String XML_PLAY_1 = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\r\n" + 
			"<status etag=\"f6a6f01ed8e04b10acfd10beb58c3a17\">\r\n" + 
			"<album>Easy Come, Easy Go</album>\r\n" + 
			"<artist>Marianne Faithfull</artist>\r\n" + 
			"<canMovePlayback>true</canMovePlayback>\r\n" + 
			"<canSeek>1</canSeek>\r\n" + 
			"<cursor>287</cursor>\r\n" + 
			"<fn>Tidal:65311633</fn>\r\n" + 
			"<image>/Artwork?service=Tidal&amp;songid=Tidal%3A65311633</image>\r\n" + 
			"<indexing>0</indexing>\r\n" + 
			"<mid>11</mid>\r\n" + 
			"<mode>1</mode>\r\n" + 
			"<name>Down from Dover</name>\r\n" + 
			"<pid>2446</pid>\r\n" + 
			"<prid>0</prid>\r\n" + 
			"<quality>cd</quality>\r\n" + 
			"<repeat>2</repeat>\r\n" + 
			"<service>Tidal</service>\r\n" + 
			"<serviceIcon>Sources/images/TidalIcon.png</serviceIcon>\r\n" + 
			"<shuffle>0</shuffle>\r\n" + 
			"<sid>3</sid>\r\n" + 
			"<sleep></sleep>\r\n" + 
			"<song>277</song>\r\n" + 
			"<state>play</state>\r\n" + 
			"<streamFormat>FLAC 44100/16/2</streamFormat>\r\n" + 
			"<syncStat>26</syncStat>\r\n" + 
			"<title1>Down from Dover</title1>\r\n" + 
			"<title2>Marianne Faithfull</title2>\r\n" + 
			"<title3>Easy Come, Easy Go</title3>\r\n" + 
			"<totlen>283</totlen>\r\n" + 
			"<volume>45</volume>\r\n" + 
			"<secs>4</secs>\r\n" + 
			"</status>";
	
	@Test
	public void monitorMustCreateUrlWithEtag() throws Throwable {
		List<String> urls = new ArrayList<>();
		
		httpRequestFactory.setGetUrlRequestedCallback((index, url, accept) -> {
			urls.add(url);
			return toInputStream(XML_PLAY_1);
		});

		Union monitorState1 = (Union)monitorPlayerInvoker.invoke(blueOsPlayerMonitor);
		// union MonitorStateTypes.MonitorSong{Song=struct Song{name=Down from Dover, artist=Marianne Faithfull, album=Easy Come, Easy Go, position=4, length=283}}
		assertTrue(monitorState1.getClass().getName().equals("audiostreamerscrobbler.states.monitor.types.MonitorStateTypes$MonitorSong"));
		
		Tuple monitorState1Members = monitorState1.destruct();
		assertEquals(1, monitorState1Members.size());
		GoloStruct song = (GoloStruct)monitorState1Members.get(0);
		
		assertEquals("Down from Dover", song.get("name"));
		assertEquals("Marianne Faithfull", song.get("artist"));
		assertEquals("Easy Come, Easy Go", song.get("album"));
		assertEquals(4, song.get("position"));
		assertEquals(283, song.get("length"));

		// First request is used to fetch etag, so that it can be added to future requests
		assertEquals(1, urls.size());
		assertEquals("http://Host:Port/Status", urls.get(0));

		// Do same request again and ensure that etag and timeout are now added to request
		monitorPlayerInvoker.invoke(blueOsPlayerMonitor);
		assertEquals(2, urls.size());
		assertEquals("http://Host:Port/Status?etag=f6a6f01ed8e04b10acfd10beb58c3a17&timeout=60", urls.get(1));
	}
	
	private InputStream toInputStream(String data) {
		try {
			return new ByteArrayInputStream(data.getBytes("UTF-8"));
		} catch (Exception ex) {
			throw new RuntimeException(ex);
		}
	}
	
}
