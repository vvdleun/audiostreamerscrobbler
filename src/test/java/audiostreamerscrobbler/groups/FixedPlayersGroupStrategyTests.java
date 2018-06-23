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
import audiostreamerscrobbler.mocks.PlayerTypes;
import gololang.Tuple;
import gololang.Union;

public class FixedPlayersGroupStrategyTests extends GroupTests {
	// Create expected players
	private Map<String, List<String>> expectedPlayers;
	private FixedPlayersGroupStrategyFacade fixedPlayersGroupStrategy;
	private final audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("GroupWithPlayersOfDifferentTypes");
	
	@Before
	public void before() {
		expectedPlayers = new HashMap<>();
		processedEvents.clear();
		fixedPlayersGroupStrategy = FixedPlayersGroupStrategyFacade.createStrategyImplFacade(expectedPlayers, cbProcessEventFunctionReference);
	}

	@Test
	public void detectedExpectedPlayersMustBeAdded() {
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();

		// Create expected players
		List<String> expectedBluOsPlayerIds = new ArrayList<>();
		expectedBluOsPlayerIds.add("foundPlayer");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), expectedBluOsPlayerIds);

		// Create player that will be detected
		Player foundPlayer = Player.createMockedPlayer("foundPlayer", bluOsPlayerType);
		
		// Create Detected event for the player
		GroupEvents.DetectedEvent detectedEvent = GroupEvents.createMockedDetectedEvent(foundPlayer);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent);

		assertEquals(1, fixedPlayersGroupStrategy.players().size());
	}
	
	@Test
	public void whenDetectingAndMorePlayersAreExpectedDoNotStopDetectors() {
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();

		// Create expected players
		List<String> expectedBluOsPlayerIds = new ArrayList<>();
		expectedBluOsPlayerIds.add("foundPlayer");
		expectedBluOsPlayerIds.add("notFoundPlayer");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), expectedBluOsPlayerIds);
		
		// Create player that will be detected
		Player foundPlayer = Player.createMockedPlayer("foundPlayer", bluOsPlayerType);
		
		// Create Detected event for the player
		GroupEvents.DetectedEvent detectedEvent = GroupEvents.createMockedDetectedEvent(foundPlayer);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent);

		assertTrue(processedEvents.isEmpty());
	}

	@Test
	public void whenAllExpectedPlayersAreDetectedStopDetectorForThatType() {
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();

		List<String> expectedBluOsPlayerIds = new ArrayList<>();
		expectedBluOsPlayerIds.add("foundPlayer1");
		expectedBluOsPlayerIds.add("foundPlayer2");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), expectedBluOsPlayerIds);

		// Create foundPlayer1 and create/send event that will detect the player
		Player foundPlayer1 = Player.createMockedPlayer("foundPlayer1", bluOsPlayerType);
		GroupEvents.DetectedEvent detectedEvent1 = GroupEvents.createMockedDetectedEvent(foundPlayer1);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent1);

		assertTrue(processedEvents.isEmpty());

		// Create foundPlayer2 and create/send event that will detect the player
		Player foundPlayer2 = Player.createMockedPlayer("foundPlayer2", bluOsPlayerType);
		GroupEvents.DetectedEvent detectedEvent2 = GroupEvents.createMockedDetectedEvent(foundPlayer2);
		fixedPlayersGroupStrategy.handleDetectedEvent(group, detectedEvent2);

		assertEquals(1, processedEvents.size());
		
		Union stopDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopDetectors", stopDetectors.getClass().getName());
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());

		Tuple stopDetectorsPlayerTypes = (Tuple)stopDetectorsMembers.get(0);
		assertThat(stopDetectorsPlayerTypes, contains(bluOsPlayerType));
	}

	@Test
	public void whenAPlayerIsLostItMustHaveBeenRemovedAndIsDetectorMustBeStarted() {
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		
		List<String> bluOsPlayers = new ArrayList<>();
		bluOsPlayers.add("player");
		expectedPlayers.put(bluOsPlayerType.playerTypeId(), bluOsPlayers);
		
		// Create and add player and create/send event that will detect the player
		Player player = Player.createMockedPlayer("player", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(player);
		
		// Create and send lost event
		GroupEvents.LostEvent lostEvent = GroupEvents.createMockedLostEvent(player);
		fixedPlayersGroupStrategy.handleLostEvent(group, lostEvent);

		assertTrue(fixedPlayersGroupStrategy.players().isEmpty());
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$startDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(bluOsPlayerType));
	}
	
	@Test
	public void handleIdleEventShouldStartIdlePlayerDetectors() throws Throwable {
		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(playingPlayer);
		markPlayerAsPlaying(fixedPlayersGroupStrategy.players(), "PlayingBluOsPlayerId");
		
		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		fixedPlayersGroupStrategy.addPlayer(idlePlayer);

		// Create Idle event for the previously playing player
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		fixedPlayersGroupStrategy.handleIdleEvent(group, idleEvent);

		assertEquals(1, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$startDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(musicCastPlayerType));
	}
	
	@Test
	public void handleIdleEventShouldIncludePlayingPlayerTypeDetectorIfMoreThanOnePlayerOfThatTypeIsInGroup() throws Throwable {
		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();

		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId1", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(playingPlayer);
		markPlayerAsPlaying(fixedPlayersGroupStrategy.players(), "PlayingBluOsPlayerId1");
		
		Player idlePlayer = Player.createMockedPlayer("IdleBluOsPlayerId2", bluOsPlayerType);
		fixedPlayersGroupStrategy.addPlayer(idlePlayer);

		// Create Idle event and pass to handler function
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		fixedPlayersGroupStrategy.handleIdleEvent(group, idleEvent);

		assertEquals(1, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$startDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(bluOsPlayerType));
	}
}
