package audiostreamerscrobbler.groups;

import gololang.DynamicObject;
import gololang.FunctionReference;
import gololang.Tuple;
import gololang.Union;

import org.junit.Before;
import org.junit.Test;

import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import audiostreamerscrobbler.mocks.PlayerStatus;
import audiostreamerscrobbler.mocks.PlayerTypes;

import static java.lang.invoke.MethodType.genericMethodType;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.*;
import static org.hamcrest.Matchers.*;

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;


public class BaseGroupStragegyImplTests {
	private static List<Object> processedEvents = new ArrayList<>();

	private static FunctionReference cbProcessEventFunctionReference = createFunctionReferenceToCbProcessEvent();
	
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

		Player mockedPlayer = createMockedPlayer("playerId");
		
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

		Player mockedPlayer = createMockedPlayer("playerId");
		
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);
		groupStrategyImpl.invoker("removePlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);

		LinkedHashMap players = (LinkedHashMap)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
		assertTrue(players.isEmpty());
	}
	
	@Test
	public void playerThatIsInGroupShouldBeFound() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);

		Player mockedPlayer = createMockedPlayer("playerId");
		
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);

		Boolean hasPlayer = (Boolean)groupStrategyImpl.invoker("hasPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);
		assertTrue(hasPlayer);
	}

	@Test
	public void playerThatIsNotInGroupShouldNotBeFound() throws Throwable {
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(null);

		Player mockedPlayerThatIsNotInGroup = createMockedPlayer("playerIdNotInGroup");
		
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
		audiostreamerscrobbler.mocks.Group group = mock(audiostreamerscrobbler.mocks.Group.class);
		when(group.name()).thenReturn("GroupName");

		// Create and initialize GroupStrategyImpl DynamicObject
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(cbProcessEventFunctionReference);

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createBluOsPlayerType();
		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMusicCastPlayerType();
		Player playingPlayer = createAndAddPlayerToGroup(groupStrategyImpl, bluOsPlayerType, "PlayingBluOsPlayerId", true);
		Player idlePlayer = createAndAddPlayerToGroup(groupStrategyImpl, musicCastPlayerType,"IdleMusicCastPlayerId", false);

		// Create PlayingEvent event and pass to handler function
		GroupEvents.PlayingEvent playingEvent = GroupEvents.createPlayingEvent(playingPlayer);
		groupStrategyImpl.invoker("handlePlayingEvent", genericMethodType(3)).invoke(groupStrategyImpl, group, playingEvent);

		assertEquals(2, processedEvents.size());
		
		Union stopDetectors = (Union)processedEvents.get(0);
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());

		Set<Object> stopDetectorsPlayerTypes = (Set<Object>)stopDetectorsMembers.get(0);
		assertThat(stopDetectorsPlayerTypes, containsInAnyOrder(playingPlayer.playerType(), idlePlayer.playerType()));

		Union stopMonitors = (Union)processedEvents.get(1);
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());

		Tuple stopMonitorsPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertThat(stopMonitorsPlayers, containsInAnyOrder(idlePlayer));
	}
	
	@SuppressWarnings("unchecked")
	@Test
	public void handleIdleEventShouldStartIdlePlayersDetectors() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = createMockedGroup("GroupWithPlayersOfDifferentTypes");
		
		// Create and initialize GroupStrategyImpl DynamicObject
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(cbProcessEventFunctionReference);

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createBluOsPlayerType();
		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMusicCastPlayerType();
		Player playingPlayer = createAndAddPlayerToGroup(groupStrategyImpl, bluOsPlayerType, "PlayingBluOsPlayerId", true);
		createAndAddPlayerToGroup(groupStrategyImpl, musicCastPlayerType, "IdleMusicCastPlayerId", false);

		// Create Idle event and pass to handler function
		GroupEvents.IdleEvent idleEvent = GroupEvents.createIdleEvent(playingPlayer);
		groupStrategyImpl.invoker("handleIdleEvent", genericMethodType(3)).invoke(groupStrategyImpl, group, idleEvent);

		assertEquals(1, processedEvents.size());
		
		Union startDetectors = (Union)processedEvents.get(0);
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Set<Object> startDetectorsPlayerTypes = (Set<Object>)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, containsInAnyOrder(musicCastPlayerType));
	}

	@SuppressWarnings("unchecked")
	@Test
	public void handleIdleEventShouldIncludePlayingPlayerTypeDetectorIfMoreThanOnePlayerOfThatTypeIsInGroup() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = createMockedGroup("GroupWithPlayersOfSameType");
		
		// Create and initialize GroupStrategyImpl DynamicObject
		DynamicObject groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(cbProcessEventFunctionReference);

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createBluOsPlayerType();
		Player playingPlayer = createAndAddPlayerToGroup(groupStrategyImpl, bluOsPlayerType, "PlayingBluOsPlayerId1", true);
		createAndAddPlayerToGroup(groupStrategyImpl, bluOsPlayerType, "IdleBluOsPlayerId2", false);

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
	
	@SuppressWarnings("unused")
	private static Object cbProcessEvent(Object event) {
		processedEvents.add(event);
		return null;
	}

	// Helpers

	private static Player createAndAddPlayerToGroup(DynamicObject groupStrategyImpl, PlayerTypes playerType, String playerId, boolean isPlaying) throws Throwable {
		// Create and add playing BluOs player to group
		Player mockedPlayer = createMockedPlayer(playerId, playerType);
		
		groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, mockedPlayer);

		if (isPlaying) {
			markPlayerAsPlaying(groupStrategyImpl, playerId);
		}
		
		return mockedPlayer;
	}
	
	@SuppressWarnings("unchecked")
	private static void markPlayerAsPlaying(DynamicObject groupStrategyImpl, String playerId) throws Throwable {
		// Mark player as playing
		Map<Object, Object> mapPlayers = (Map<Object, Object>)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
		Map<Object, Object> mapPlayer = (Map<Object, Object>)mapPlayers.get(playerId);
		mapPlayer.put("state", PlayerStatus.createPlayingPlayerStatus());
	}

	private static audiostreamerscrobbler.mocks.Player createMockedPlayer(String playerId, PlayerTypes playerType) {
		Player mockedPlayer = createMockedPlayer(playerId);
		when(mockedPlayer.playerType()).thenReturn(playerType);

		return mockedPlayer;
	}

	private static audiostreamerscrobbler.mocks.Player createMockedPlayer(String playerId) {
		Player mockedPlayer = mock(Player.class);
		when(mockedPlayer.id()).thenReturn(playerId);
		return mockedPlayer;
	}

	private static audiostreamerscrobbler.mocks.Group createMockedGroup(String groupName) {
		audiostreamerscrobbler.mocks.Group group = mock(audiostreamerscrobbler.mocks.Group.class);
		when(group.name()).thenReturn(groupName);
		return group;
	}

	private static FunctionReference createFunctionReferenceToCbProcessEvent() {
		try {
			return createFunctionReference(BaseGroupStragegyImplTests.class, "cbProcessEvent", 1);
		} catch (Throwable  t) {
			throw new RuntimeException(t);
		}
	}
	
	private static FunctionReference createFunctionReference(Class<?> clazz, String methodName, int parameters) throws Throwable {
		MethodHandles.Lookup lookup = MethodHandles.lookup();
		MethodHandle handle = lookup.findStatic(clazz, methodName, genericMethodType(parameters));
		return new FunctionReference(handle);
	}
} 