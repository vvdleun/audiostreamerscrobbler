package audiostreamerscrobbler.groups;

import gololang.FunctionReference;
import gololang.Tuple;
import gololang.Union;

import org.junit.Before;
import org.junit.Test;

import audiostreamerscrobbler.facades.GroupStrategyImplFacade;
import audiostreamerscrobbler.mocks.GoloUtils;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import audiostreamerscrobbler.mocks.PlayerStatus;
import audiostreamerscrobbler.mocks.PlayerTypes;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.hamcrest.Matchers.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;


public class BaseGroupStragegyImplTests {
	private static GroupStrategyImplFacade groupStrategyImpl;
	private static final FunctionReference cbProcessEventFunctionReference = createFunctionReferenceToCbProcessEvent();
	private static final List<Object> processedEvents = new ArrayList<>();
	
	@Before
	public void before() {
		groupStrategyImpl = GroupStrategyImplFacade.createStrategyImplFacade(cbProcessEventFunctionReference);
		processedEvents.clear();
	}
	
	@Test
	public void shouldBeInitiallyEmpty() throws Throwable {
		LinkedHashMap<Object, Object> players = groupStrategyImpl.players();
		assertTrue(players.isEmpty());
	}
	
	@Test
	@SuppressWarnings("unchecked")
	public void addedPlayerShouldBeAddedToGroup() throws Throwable {
		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.addPlayer(mockedPlayer);

		LinkedHashMap<Object, Object> players = groupStrategyImpl.players();
		assertEquals(1, players.size());
		
		LinkedHashMap<Object, Object> playerMap = (LinkedHashMap<Object, Object>)players.get("playerId");
		assertEquals("audiostreamerscrobbler.groups.BaseGroupStragegyImpl.types.PlayerStatus$Idle", ((Union)playerMap.get("state")).getClass().getName());
		assertEquals(mockedPlayer, playerMap.get("player"));
	}
	
	@Test
	public void removedPlayerShouldBeRemovedFromGroup() throws Throwable {
		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.addPlayer(mockedPlayer);
		groupStrategyImpl.removePlayer(mockedPlayer);

		LinkedHashMap<Object, Object> players = groupStrategyImpl.players();
		assertTrue(players.isEmpty());
	}
	
	@Test
	public void playerThatIsInGroupShouldBeFound() throws Throwable {
		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.addPlayer(mockedPlayer);

		assertTrue(groupStrategyImpl.hasPlayer(mockedPlayer));
	}

	@Test
	public void playerThatIsNotInGroupShouldNotBeFound() throws Throwable {
		Player mockedPlayerThatIsNotInGroup = Player.createMockedPlayer("playerIdNotInGroup");

		assertFalse(groupStrategyImpl.hasPlayer(mockedPlayerThatIsNotInGroup));
	}

	@Test(expected = IllegalStateException.class)	
	public void handleDetectedEventShouldThrowException() throws Throwable {
		groupStrategyImpl.handleDetectedEvent(null, null);
	}

	@Test(expected = IllegalStateException.class)	
	public void handleLostEventShouldThrowException() throws Throwable {
		groupStrategyImpl.handleLostEvent(null, null);
	}
	
	@SuppressWarnings("unchecked")
	@Test
	public void handlePlayingEventShouldStopAllDetectorsAndOtherMonitors() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("Group");

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		groupStrategyImpl.addPlayer(playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId");

		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		groupStrategyImpl.addPlayer(idlePlayer);

		// Create PlayingEvent event and pass to handler function
		GroupEvents.PlayingEvent playingEvent = GroupEvents.createMockedPlayingEvent(playingPlayer);
		groupStrategyImpl.handlePlayingEvent(group, playingEvent);

		assertEquals(2, processedEvents.size());
		
		Union stopDetectors = (Union)processedEvents.get(0);
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());

		Set<Object> stopDetectorsPlayerTypes = (Set<Object>)stopDetectorsMembers.get(0);
		assertThat(stopDetectorsPlayerTypes, containsInAnyOrder(bluOsPlayerType, musicCastPlayerType));

		Union stopMonitors = (Union)processedEvents.get(1);
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());

		Tuple stopMonitorsPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertThat(stopMonitorsPlayers, contains(idlePlayer));
	}
	
	@SuppressWarnings("unchecked")
	@Test
	public void handleIdleEventShouldStartIdlePlayersDetectors() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("GroupWithPlayersOfDifferentTypes");
		
		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		groupStrategyImpl.addPlayer(playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId");
		
		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		groupStrategyImpl.addPlayer(idlePlayer);

		// Create Idle event for the previously playing player
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		groupStrategyImpl.handleIdleEvent(group, idleEvent);

		assertEquals(1, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Set<Object> startDetectorsPlayerTypes = (Set<Object>)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(musicCastPlayerType));
	}

	@SuppressWarnings("unchecked")
	@Test
	public void handleIdleEventShouldIncludePlayingPlayerTypeDetectorIfMoreThanOnePlayerOfThatTypeIsInGroup() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("GroupWithPlayersOfSameType");

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();

		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId1", bluOsPlayerType);
		groupStrategyImpl.addPlayer(playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId1");
		
		Player idlePlayer = Player.createMockedPlayer("IdleBluOsPlayerId2", bluOsPlayerType);
		groupStrategyImpl.addPlayer(idlePlayer);

		// Create Idle event and pass to handler function
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		groupStrategyImpl.handleIdleEvent(group, idleEvent);

		assertEquals(1, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Set<Object> startDetectorsPlayerTypes = (Set<Object>)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, containsInAnyOrder(bluOsPlayerType));
	}

	// Callback functions

	public static Object cbProcessEvent(Object event) {
		processedEvents.add(event);
		return null;
	}

	// Helpers

	@SuppressWarnings("unchecked")
	private static void markPlayerAsPlaying(GroupStrategyImplFacade groupStrategyImpl, String playerId) throws Throwable {
		// Mark player as playing
		Map<Object, Object> mapPlayers = groupStrategyImpl.players();
		Map<Object, Object> mapPlayer = (Map<Object, Object>)mapPlayers.get(playerId);
		mapPlayer.put("state", PlayerStatus.createMockedPlayingPlayerStatus());
	}

	private static FunctionReference createFunctionReferenceToCbProcessEvent() {
		try {
			return GoloUtils.createFunctionReference(BaseGroupStragegyImplTests.class, "cbProcessEvent", 1);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
} 