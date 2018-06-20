package audiostreamerscrobbler.groups;

import gololang.DynamicObject;
import gololang.FunctionReference;
import gololang.Tuple;
import gololang.Union;

import org.junit.Before;
import org.junit.Test;

import audiostreamerscrobbler.mocks.GoloUtils;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import audiostreamerscrobbler.mocks.PlayerStatus;
import audiostreamerscrobbler.mocks.PlayerTypes;

import static java.lang.invoke.MethodType.genericMethodType;
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
	private static FunctionReference cbProcessEventFunctionReference = createFunctionReferenceToCbProcessEvent();
	private static List<Object> processedEvents = new ArrayList<>();
	
	@Before
	public void before() {
		processedEvents.clear();
	}
	
	@Test
	@SuppressWarnings("rawtypes")
	public void shouldBeInitiallyEmpty() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);
		LinkedHashMap players = (LinkedHashMap)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
		assertEquals(0, players.size());
	}
	
	@Test
	@SuppressWarnings("rawtypes")
	public void addedPlayerShouldBeAddedToGroup() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);

		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);

		LinkedHashMap players = (LinkedHashMap)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
		assertEquals(1, players.size());
		
		LinkedHashMap playerMap = (LinkedHashMap)players.get("playerId");
		assertEquals("audiostreamerscrobbler.groups.BaseGroupStragegyImpl.types.PlayerStatus$Idle", ((Union)playerMap.get("state")).getClass().getName());
		assertEquals(mockedPlayer, playerMap.get("player"));
	}
	
	@Test
	@SuppressWarnings("rawtypes")
	public void removedPlayerShouldBeRemovedFromGroup() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);

		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);
		groupStrategyImpl.invoker("removePlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);

		LinkedHashMap players = (LinkedHashMap)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
		assertTrue(players.isEmpty());
	}
	
	@Test
	public void playerThatIsInGroupShouldBeFound() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);

		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);

		Boolean hasPlayer = (Boolean)groupStrategyImpl.invoker("hasPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);
		assertTrue(hasPlayer);
	}

	@Test
	public void playerThatIsNotInGroupShouldNotBeFound() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);

		Player mockedPlayerThatIsNotInGroup = Player.createMockedPlayer("playerIdNotInGroup");

		Boolean hasPlayer = (Boolean)groupStrategyImpl.invoker("hasPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayerThatIsNotInGroup);
		assertFalse(hasPlayer);
	}

	@Test(expected = IllegalStateException.class)	
	public void handleDetectedEventShouldThrowException() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);
		groupStrategyImpl.invoker("handleDetectedEvent", genericMethodType(3)).invoke(groupStrategyImpl, null, null);
	}

	@Test(expected = IllegalStateException.class)	
	public void handleLostEventShouldThrowException() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);
		groupStrategyImpl.invoker("handleLostEvent", genericMethodType(3)).invoke(groupStrategyImpl, null, null);
	}

	@SuppressWarnings("unchecked")
	@Test
	public void handlePlayingEventShouldStopAllDetectorsAndOtherMonitors() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("Group");

		// Create and initialize GroupStrategyImpl DynamicObject
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(cbProcessEventFunctionReference);

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createBluOsPlayerType();
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId");

		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMusicCastPlayerType();
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, idlePlayer);

		// Create PlayingEvent event and pass to handler function
		GroupEvents.PlayingEvent playingEvent = GroupEvents.createPlayingEvent(playingPlayer);
		groupStrategyImpl.invoker("handlePlayingEvent", genericMethodType(3)).invoke(groupStrategyImpl, group, playingEvent);

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
		
		// Create and initialize GroupStrategyImpl DynamicObject
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(cbProcessEventFunctionReference);

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createBluOsPlayerType();
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId");
		
		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMusicCastPlayerType();
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, idlePlayer);

		// Create Idle event for the previously playing player
		GroupEvents.IdleEvent idleEvent = GroupEvents.createIdleEvent(playingPlayer);
		groupStrategyImpl.invoker("handleIdleEvent", genericMethodType(3)).invoke(groupStrategyImpl, group, idleEvent);

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

		// Create and initialize GroupStrategyImpl DynamicObject
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(cbProcessEventFunctionReference);

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createBluOsPlayerType();

		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId1", bluOsPlayerType);
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId1");
		
		Player idlePlayer = Player.createMockedPlayer("IdleBluOsPlayerId2", bluOsPlayerType);
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, idlePlayer);

		// Create Idle event and pass to handler function
		GroupEvents.IdleEvent idleEvent = GroupEvents.createIdleEvent(playingPlayer);
		groupStrategyImpl.invoker("handleIdleEvent", genericMethodType(3)).invoke(groupStrategyImpl, group, idleEvent);

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
	private static void markPlayerAsPlaying(DynamicObject groupStrategyImpl, String playerId) throws Throwable {
		// Mark player as playing
		Map<Object, Object> mapPlayers = (Map<Object, Object>)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
		Map<Object, Object> mapPlayer = (Map<Object, Object>)mapPlayers.get(playerId);
		mapPlayer.put("state", PlayerStatus.createPlayingPlayerStatus());
	}

	private static FunctionReference createFunctionReferenceToCbProcessEvent() {
		try {
			return GoloUtils.createFunctionReference(BaseGroupStragegyImplTests.class, "cbProcessEvent", 1);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
} 