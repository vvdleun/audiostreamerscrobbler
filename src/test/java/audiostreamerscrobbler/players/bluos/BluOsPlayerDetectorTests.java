package audiostreamerscrobbler.players.bluos;

import audiostreamerscrobbler.players.bluos.BluOsDetector;

import gololang.DynamicObject;
import gololang.FunctionReference;
import gololang.GoloStruct;
import gololang.Tuple;
import gololang.Union;
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;

import org.junit.Before;
import org.junit.Test;

import static java.lang.invoke.MethodType.genericMethodType;
import static org.junit.Assert.*;

public class BluOsPlayerDetectorTests {
	@Before
	public void init() {
		MockedLSDPHandler.reportedPlayer = null;
	}

	@Test
	public void shouldContinueSearchWhenPlayerNotFound() throws Throwable {
		Object socketFactory = new Object();
		DynamicObject bluOsDetector = (DynamicObject)BluOsDetector.createBluOsDetector(socketFactory, );
		DynamicObject lsdpHandler = createMockedLSDPHandler(MockedLSDPHandler.class, "queryLsdpPlayerNotFound");

		MethodHandle detectPlayerInvoker = setupBlueOsDetectorAndCreateDetectPlayerInvoker(bluOsDetector, lsdpHandler);
		Union u = (Union)detectPlayerInvoker.invoke(bluOsDetector);

		assertEquals("audiostreamerscrobbler.states.detector.DetectorStateTypes.types.DetectorStateTypes$PlayerNotFoundKeepTrying", u.getClass().getName());

		Tuple unionMembers = u.destruct();
		assertEquals(0, unionMembers.size());
	}

	@Test
	public void shouldReturnPlayerWhenExpectedPlayerIsFound() throws Throwable {
		MockedLSDPHandler.reportedPlayer = "SearchedPlayer";

		Object socketFactory = new Object();
		DynamicObject bluOsDetector = (DynamicObject)BluOsPlayerDetector.createBluOsPlayerDetector("SearchedPlayer");
		DynamicObject lsdpHandler = createMockedLSDPHandler(MockedLSDPHandler.class, "queryLsdpReportedPlayerFound");

		MethodHandle detectPlayerInvoker = setupBlueOsDetectorAndCreateDetectPlayerInvoker(bluOsDetector, lsdpHandler);
		Union u = (Union)detectPlayerInvoker.invoke(bluOsDetector);

		Tuple unionMembers = u.destruct();
		assertEquals(1, unionMembers.size());

		DynamicObject foundPlayer = (DynamicObject)unionMembers.get(0);
		assertEquals("SearchedPlayer", (String)foundPlayer.get("name"));
		Union playerType = (Union)foundPlayer.get("playerType");
		assertEquals("audiostreamerscrobbler.maintypes.Player.types.PlayerTypes$BluOs", playerType.getClass().getName());

		Tuple playerTypeMembers = playerType.destruct();
		assertEquals(1, playerTypeMembers.size());

		GoloStruct bluOsImpl = (GoloStruct)playerTypeMembers.get(0);
		assertEquals("SearchedPlayer", bluOsImpl.get("name"));
		assertEquals("1234", bluOsImpl.get("port"));
		assertEquals("She's a model and she's looking good", bluOsImpl.get("model"));
		assertEquals("v1.0.0.0.1b", bluOsImpl.get("version"));
		assertEquals("01:02:03:04", bluOsImpl.get("macAddress"));
		assertEquals("5.6.7.8.9", bluOsImpl.get("ipAddress"));
		assertEquals("1", bluOsImpl.get("LSDPVersionSupposedly"));
		assertNotNull(bluOsImpl.get("host"));

		assertEquals("audiostreamerscrobbler.states.detector.DetectorStateTypes.types.DetectorStateTypes$PlayerFound", u.getClass().getName());
	}

	@Test
	public void shouldKeepSearchingWhenUnwantedPlayerIsDetected() throws Throwable {
		MockedLSDPHandler.reportedPlayer = "ThisIsNotThePlayerThatYouAreLookingFor";
		
		DynamicObject bluOsDetector = (DynamicObject)BluOsPlayerDetector.createBluOsPlayerDetector(socketFactory, null);
		DynamicObject lsdpHandler = createMockedLSDPHandler(MockedLSDPHandler.class, "queryLsdpReportedPlayerFound");

		MethodHandle detectPlayerInvoker = setupBlueOsDetectorAndCreateDetectPlayerInvoker(bluOsDetector, lsdpHandler);
		Union u = (Union)detectPlayerInvoker.invoke(bluOsDetector);

		assertEquals(0, ((Tuple)u.destruct()).size());

		assertEquals("audiostreamerscrobbler.states.detector.DetectorStateTypes.types.DetectorStateTypes$PlayerNotFoundKeepTrying", u.getClass().getName());
	}

	private MethodHandle setupBlueOsDetectorAndCreateDetectPlayerInvoker(DynamicObject bluOsDetector, DynamicObject lsdpHandler) throws Throwable {
		MethodHandle setLsdpHandlerInvoker = bluOsDetector.invoker("_lsdpHandler", genericMethodType(2));
		setLsdpHandlerInvoker.invoke(bluOsDetector, lsdpHandler);
		return bluOsDetector.invoker("detectPlayer", genericMethodType(1));
	}

	private DynamicObject createMockedLSDPHandler(Class<?> className, String queryLSDPplayersMethodName) throws Exception {
		MethodHandles.Lookup lookup = MethodHandles.lookup();
		MethodHandle handle = lookup.findStatic(className, queryLSDPplayersMethodName, genericMethodType(4));
		FunctionReference queryLSDPPlayersRef = new FunctionReference(handle);
		
		DynamicObject lsdpHandler = new DynamicObject();
		lsdpHandler.define("queryLSDPPlayers", queryLSDPPlayersRef);
		return lsdpHandler;
	}

	private static class MockedLSDPHandler {
		public static String reportedPlayer = null;
		
		@SuppressWarnings({ "unchecked", "unused" })
		public static Object queryLsdpPlayerNotFound(Object lsdpHandler, Object inetAddresses, Object timeout, Object playerAnswerCallback) {
			assertNotNull(lsdpHandler);
			((List<Object>)inetAddresses).stream()
				.map(o -> (InetAddress) o)
				.collect(Collectors.toList());
			assertEquals(5, timeout);
			assertTrue(playerAnswerCallback instanceof FunctionReference);
			return null;
		}

		@SuppressWarnings({ "unchecked", "unused" })
		public static Object queryLsdpReportedPlayerFound(Object lsdpHandler, Object inetAddresses, Object timeout, Object playerAnswerCallback) throws Throwable {
			FunctionReference callback = (FunctionReference)playerAnswerCallback;

			HashMap<String, String> table01 = new HashMap<>();
			table01.put("name", reportedPlayer); // Must be set by test before this method is called
			table01.put("port", "1234");
			table01.put("model", "She's a model and she's looking good");
			table01.put("version", "v1.0.0.0.1b");
			HashMap<Integer, HashMap<String, String>> t1 = new HashMap<>();
			t1.put(1, table01);
			HashMap<Integer, HashMap<Integer, HashMap<String, String>>> t0 = new HashMap<>();
			t0.put(0, t1);
			
			HashMap<Object, Object> mockedExtractedLSDPPlayer = new HashMap<>();
			mockedExtractedLSDPPlayer.put("lsdpVersionSupposedly", "1");
			mockedExtractedLSDPPlayer.put("answerType", "A");
			mockedExtractedLSDPPlayer.put("macAddress", "01:02:03:04");
			mockedExtractedLSDPPlayer.put("ipAddress", "5.6.7.8.9");
			mockedExtractedLSDPPlayer.put("tables", t0);

			DatagramPacket datagramPacket = new DatagramPacket(new byte[0], 0);
			datagramPacket.setAddress(InetAddress.getLocalHost());
			
			callback.invoke(mockedExtractedLSDPPlayer, datagramPacket);

			assertNotNull(lsdpHandler);
			((List<Object>)inetAddresses).stream()
				.map(o -> (InetAddress) o)
				.collect(Collectors.toList());
			assertEquals(5, timeout);
			
			return null;
		}
	}	
}