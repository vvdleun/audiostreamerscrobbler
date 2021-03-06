package audiostreamerscrobbler.groups;

import static org.hamcrest.Matchers.contains;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.Before;
import org.junit.Test;

import audiostreamerscrobbler.facades.FixedPlayersGroupStrategyFacade;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import gololang.Tuple;
import gololang.Union;

public class FixedPlayersGroupStrategyTests extends GroupTests {
	private Map<String, List<String>> expectedPlayers;
	private FixedPlayersGroupStrategyFacade fixedPlayersGroupStrategy;
	private final audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("FixedPlayersGroupStrategyGroup");
	
	@Before
	public void before() {
		expectedPlayers = new HashMap<>();
		processedEvents.clear();
		fixedPlayersGroupStrategy = FixedPlayersGroupStrategyFacade.createStrategyImplFacade(expectedPlayers, cbProcessEventFunctionReference);
	}

	@Test
	public void detectedExpectedPlayersMustBeAdded() {
		// Create expected players
		List<String> expectedBluOsPlayerIds = new ArrayList<>();
		expectedBluOsPlayerIds.add("foundPlayer");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), expectedBluOsPlayerIds);

		// Must be set explicitly because this list is initialized when creating the fixedPlayersGroupStrategy instance
		fixedPlayersGroupStrategy.playerTypes().add(bluOsPlayerType);

		// Create player that will be detected
		Player foundPlayer = Player.createMockedPlayer("foundPlayer", bluOsPlayerType);
		
		// Create Detected event for the player
		GroupEvents.DetectedEvent detectedEvent = GroupEvents.createMockedDetectedEvent(foundPlayer);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent);

		assertEquals(1, fixedPlayersGroupStrategy.players().size());
	}
	
	@Test
	public void whenDetectingAndMorePlayersAreExpectedDoNotStopDetectorsButStartMonitor() {
		// Create expected players
		List<String> expectedBluOsPlayerIds = new ArrayList<>();
		expectedBluOsPlayerIds.add("foundPlayer");
		expectedBluOsPlayerIds.add("notFoundPlayer");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), expectedBluOsPlayerIds);

		// Must be set explicitly because this list is initialized when creating the fixedPlayersGroupStrategy instance
		fixedPlayersGroupStrategy.playerTypes().add(bluOsPlayerType);

		// Create player that will be detected
		Player foundPlayer = Player.createMockedPlayer("foundPlayer", bluOsPlayerType);
		
		// Create Detected event for the player
		GroupEvents.DetectedEvent detectedEvent = GroupEvents.createMockedDetectedEvent(foundPlayer);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent);

		assertEquals(1, processedEvents.size());

		Union startMonitor = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StartMonitors", startMonitor.getClass().getName());
		Tuple startMonitorMembers = startMonitor.destruct();
		assertEquals(1, startMonitorMembers.size());
		Tuple startMonitorPlayers = (Tuple)startMonitorMembers.get(0);
		assertThat(startMonitorPlayers, contains(foundPlayer));
	}

	@Test
	public void whenAllExpectedPlayersAreDetectedStopDetectorForThatTypeAndStartMonitors() {
		List<String> expectedBluOsPlayerIds = new ArrayList<>();
		expectedBluOsPlayerIds.add("foundPlayer1");
		expectedBluOsPlayerIds.add("foundPlayer2");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), expectedBluOsPlayerIds);
		
		// Must be set explicitly because this list is initialized when creating the fixedPlayersGroupStrategy instance
		fixedPlayersGroupStrategy.playerTypes().add(bluOsPlayerType);
		fixedPlayersGroupStrategy.activePlayerTypes().add(bluOsPlayerType);

		// Create foundPlayer1 and create/send event that will detect the player
		Player foundPlayer1 = Player.createMockedPlayer("foundPlayer1", bluOsPlayerType);
		GroupEvents.DetectedEvent detectedEvent1 = GroupEvents.createMockedDetectedEvent(foundPlayer1);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent1);

		// Create foundPlayer2 and create/send event that will detect the player
		Player foundPlayer2 = Player.createMockedPlayer("foundPlayer2", bluOsPlayerType);
		GroupEvents.DetectedEvent detectedEvent2 = GroupEvents.createMockedDetectedEvent(foundPlayer2);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent2);

		assertEquals(3, processedEvents.size());
		
		Union startMonitor1 = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StartMonitors", startMonitor1.getClass().getName());
		Tuple startMonitor1Members = startMonitor1.destruct();
		assertEquals(1, startMonitor1Members.size());
		Tuple startMonitor1Players = (Tuple)startMonitor1Members.get(0);
		assertThat(startMonitor1Players, contains(foundPlayer1));
		
		Union startMonitor2 = (Union)processedEvents.get(1);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StartMonitors", startMonitor2.getClass().getName());
		Tuple startMonitor2Members = startMonitor2.destruct();
		assertEquals(1, startMonitor2Members.size());
		Tuple startMonitor2Players = (Tuple)startMonitor2Members.get(0);
		assertThat(startMonitor2Players, contains(foundPlayer2));

		Union stopDetectors = (Union)processedEvents.get(2);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StopDetectors", stopDetectors.getClass().getName());
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());
		Tuple stopDetectorsPlayerTypes = (Tuple)stopDetectorsMembers.get(0);
		assertThat(stopDetectorsPlayerTypes, contains(bluOsPlayerType));
	}

	@Test
	public void whenAnIdlePlayerIsLostItMustHaveBeenRemovedAndItsDetectorMustBeStartedAndItsMonitorStopped() {
		List<String> bluOsPlayers = new ArrayList<>();
		bluOsPlayers.add("idlePlayer1");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), bluOsPlayers);

		List<String> musicCastPlayers = new ArrayList<>();
		musicCastPlayers.add("idlePlayer2");
		expectedPlayers.put(musicCastPlayerType.playerTypeId(), musicCastPlayers);
		
		// Must be set explicitly because this list is initialized when creating the fixedPlayersGroupStrategy instance
		fixedPlayersGroupStrategy.playerTypes().add(bluOsPlayerType);
		fixedPlayersGroupStrategy.playerTypes().add(musicCastPlayerType);
		
		// Create and add player and create/send event that will detect the player
		Player idlePlayer1 = Player.createMockedPlayer("idlePlayer1", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(idlePlayer1);

		Player idlePlayer2 = Player.createMockedPlayer("idlePlayer2", musicCastPlayerType);
		fixedPlayersGroupStrategy.addPlayer(idlePlayer1);
		
		// Create and send lost event
		GroupEvents.LostEvent lostEvent = GroupEvents.createMockedLostEvent(idlePlayer1);
		fixedPlayersGroupStrategy.handleLostEvent(group, lostEvent);

		assertTrue(fixedPlayersGroupStrategy.players().isEmpty());
		
		assertEquals(2, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StartDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(bluOsPlayerType));

		Union stopMonitors= (Union)processedEvents.get(1);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StopMonitors", stopMonitors.getClass().getName());
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());
		Tuple stopMonitorPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertThat(stopMonitorPlayers, contains(idlePlayer1));
	}

	@Test
	public void whenAPlayingPlayerIsLostAllDetectorsMustBeStartedAndItsMonitorStopped() {
		List<String> bluOsPlayers = new ArrayList<>();
		bluOsPlayers.add("playingBluOsPlayer");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), bluOsPlayers);

		List<String> musicCastPlayers = new ArrayList<>();
		musicCastPlayers.add("idleMusicCastPlayer");
		expectedPlayers.put(musicCastPlayerType.playerTypeId(), musicCastPlayers);
		
		// Must be set explicitly because this list is initialized when creating the fixedPlayersGroupStrategy instance
		fixedPlayersGroupStrategy.playerTypes().add(bluOsPlayerType);
		fixedPlayersGroupStrategy.playerTypes().add(musicCastPlayerType);
		
		// Create and add player and create/send event that will detect the player
		Player playingPlayer = Player.createMockedPlayer("playingBluOsPlayer", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(playingPlayer);
		markPlayerAsPlaying(fixedPlayersGroupStrategy.players(), "playingBluOsPlayer");

		Player idlePlayer = Player.createMockedPlayer("idleMusicCastPlayer", musicCastPlayerType);
		fixedPlayersGroupStrategy.addPlayer(idlePlayer);
		
		// Create and send lost event
		GroupEvents.LostEvent lostEvent = GroupEvents.createMockedLostEvent(playingPlayer);
		fixedPlayersGroupStrategy.handleLostEvent(group, lostEvent);

		assertThat(fixedPlayersGroupStrategy.players().keySet(), contains("idleMusicCastPlayer"));
		
		assertEquals(2, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StartDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(bluOsPlayerType, musicCastPlayerType));

		Union stopMonitors= (Union)processedEvents.get(1);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StopMonitors", stopMonitors.getClass().getName());
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());
		Tuple stopMonitorPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertThat(stopMonitorPlayers, contains(playingPlayer));

	}

	
	@Test
	public void handleIdleEventShouldStartIdlePlayerDetectors() throws Throwable {
		// Add expected players
		List<String> bluOsPlayerIds = new ArrayList<>();
		bluOsPlayerIds.add("PlayingBluOsPlayerId");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), bluOsPlayerIds);
		List<String> musicCastPlayerIds = new ArrayList<>();
		musicCastPlayerIds.add("IdleMusicCastPlayerId");
		expectedPlayers.put(musicCastPlayerType.playerTypeId(), musicCastPlayerIds);
		
		// Must be set explicitly because this list is initialized when creating the fixedPlayersGroupStrategy instance
		fixedPlayersGroupStrategy.playerTypes().add(bluOsPlayerType);
		fixedPlayersGroupStrategy.playerTypes().add(musicCastPlayerType);
		
		// Create and add players to group
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(playingPlayer);
		markPlayerAsPlaying(fixedPlayersGroupStrategy.players(), "PlayingBluOsPlayerId");
		
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		fixedPlayersGroupStrategy.addPlayer(idlePlayer);

		// Create Idle event for the previously playing player
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		fixedPlayersGroupStrategy.handleIdleEvent(group, idleEvent);

		assertEquals(1, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StartDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(musicCastPlayerType));
	}
	
	@Test
	public void handleIdleEventShouldIncludePlayingPlayerTypeDetectorIfMoreThanOnePlayerOfThatTypeIsInGroup() throws Throwable {
		// Add expected players
		List<String> bluOsPlayerIds = new ArrayList<>();
		bluOsPlayerIds.add("PlayingBluOsPlayerId");
		bluOsPlayerIds.add("IdleBluOsPlayerId");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), bluOsPlayerIds);

		// Must be set explicitly because this list is initialized when creating the fixedPlayersGroupStrategy instance
		fixedPlayersGroupStrategy.playerTypes().add(bluOsPlayerType);
		
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(playingPlayer);
		markPlayerAsPlaying(fixedPlayersGroupStrategy.players(), "PlayingBluOsPlayerId");
		
		Player idlePlayer = Player.createMockedPlayer("IdleBluOsPlayerId", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(idlePlayer);

		// Create Idle event and pass to handler function
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		fixedPlayersGroupStrategy.handleIdleEvent(group, idleEvent);

		assertEquals(1, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$StartDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(bluOsPlayerType));
	}
}
