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
import audiostreamerscrobbler.mocks.PlayerTypes;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.hamcrest.Matchers.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

public class BaseGroupStragegyImplTests extends GroupTests {
	private static GroupStrategyImplFacade groupStrategyImpl;
	private static boolean afterIdleEventCalled;
	
	@Before
	public void before() {
		List<PlayerTypes> playerTypes = new ArrayList<>();
		playerTypes.add(bluOsPlayerType);
		playerTypes.add(musicCastPlayerType);
		
		groupStrategyImpl = GroupStrategyImplFacade.createStrategyImplFacade(playerTypes, cbProcessEventFunctionReference);
		processedEvents.clear();
		afterIdleEventCalled = false;
	}
	
	@Test
	public void shouldBeInitiallyEmpty() {
		LinkedHashMap<Object, Object> players = groupStrategyImpl.players();
		assertTrue(players.isEmpty());
	}
	
	@Test
	@SuppressWarnings("unchecked")
	public void addedPlayerShouldBeAddedToGroupAndIdle() {
		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.addPlayer(mockedPlayer);

		LinkedHashMap<Object, Object> players = groupStrategyImpl.players();
		assertEquals(1, players.size());
		
		LinkedHashMap<Object, Object> playerMap = (LinkedHashMap<Object, Object>)players.get("playerId");
		assertEquals(mockedPlayer, playerMap.get("player"));
		assertEquals("audiostreamerscrobbler.groups.BaseGroupStragegyImpl.types.PlayerStatus$Idle", ((Union)playerMap.get("state")).getClass().getName());
	}

	@Test
	public void removedPlayerShouldBeRemovedFromGroup() {
		Player mockedPlayer = Player.createMockedPlayer("playerId");
		
		groupStrategyImpl.addPlayer(mockedPlayer);
		groupStrategyImpl.removePlayer(mockedPlayer);

		LinkedHashMap<Object, Object> players = groupStrategyImpl.players();
		assertTrue(players.isEmpty());
	}

	@Test
	public void playerThatIsInGroupShouldBeFound() {
		Player mockedPlayer = Player.createMockedPlayer("playerId");
		groupStrategyImpl.addPlayer(mockedPlayer);

		assertTrue(groupStrategyImpl.hasPlayer(mockedPlayer));
	}

	@Test
	public void playerThatIsNotInGroupShouldNotBeFound() {
		Player mockedPlayerThatIsNotInGroup = Player.createMockedPlayer("playerIdNotInGroup");

		assertFalse(groupStrategyImpl.hasPlayer(mockedPlayerThatIsNotInGroup));
	}
	
	@Test
	public void allAddedPlayersShouldBeFound() {
		Player mockedPlayer1 = Player.createMockedPlayer("playerId1");
		groupStrategyImpl.addPlayer(mockedPlayer1);

		Player mockedPlayer2 = Player.createMockedPlayer("playerId2");
		groupStrategyImpl.addPlayer(mockedPlayer2);
		
		assertThat(groupStrategyImpl.activePlayers(), containsInAnyOrder(mockedPlayer1, mockedPlayer2));
	}

	@Test
	public void playingPlayerShouldBeDetected() {
		Player playingPlayer = Player.createMockedPlayer("playingPlayer");
		groupStrategyImpl.addPlayer(playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "playingPlayer");

		Player idlePlayer = Player.createMockedPlayer("idlePlayer");
		groupStrategyImpl.addPlayer(idlePlayer);

		assertTrue(groupStrategyImpl.isPlayerInGroupPlaying());
	}

	@Test
	public void onlyIdlePlayerShouldBeDetected() {
		Player idlePlayer1 = Player.createMockedPlayer("idlePlayer1");
		groupStrategyImpl.addPlayer(idlePlayer1);

		Player idlePlayer2 = Player.createMockedPlayer("idlePlayer2");
		groupStrategyImpl.addPlayer(idlePlayer2);
		
		assertFalse(groupStrategyImpl.isPlayerInGroupPlaying());
	}

	@Test
	public void whenStartingAllDetectorsAllDetectorsMustBeStarted() {
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		Player musicCastPlayer = Player.createMockedPlayer("MusicCastPlayer", musicCastPlayerType);
		groupStrategyImpl.addPlayer(musicCastPlayer);

		groupStrategyImpl.startAllDetectors();
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$startDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, containsInAnyOrder(bluOsPlayerType, musicCastPlayerType));

		assertEquals(1, processedEvents.size());
	}

	@Test
	public void whenStartingNoDetectorNoDetectorShouldBeStarted() throws Throwable {
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		FunctionReference doNotAcceptAnyPlayerTypeReference = GoloUtils.createFunctionReference(this.getClass(), "doNotAcceptAnyPlayerType", 1);
		groupStrategyImpl.startDetectors(doNotAcceptAnyPlayerTypeReference);
		
		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$startDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertTrue(startDetectorsPlayerTypes.isEmpty());

		assertEquals(1, processedEvents.size());
	}

	public static Object doNotAcceptAnyPlayerType(Object playerType) {
		return false;
	}
	
	@Test
	public void whenAllDetectorsAreStoppedTheyShouldBeStopped() {
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		Player musicCastPlayer = Player.createMockedPlayer("MusicCastPlayer", musicCastPlayerType);
		groupStrategyImpl.addPlayer(musicCastPlayer);

		groupStrategyImpl.stopAllDetectors();
		
		Union stopDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopDetectors", stopDetectors.getClass().getName());
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());

		Tuple stopDetectorsPlayerTypes = (Tuple)stopDetectorsMembers.get(0);
		assertThat(stopDetectorsPlayerTypes, containsInAnyOrder(bluOsPlayerType, musicCastPlayerType));

		assertEquals(1, processedEvents.size());
	}

	@Test
	public void whenStoppingOnlyMusicCastDetectorsOnlyMusicCastDetectorsShouldBeStopped() throws Throwable {
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);

		Player musicCastPlayer = Player.createMockedPlayer("MusicCastPlayer", musicCastPlayerType);
		groupStrategyImpl.addPlayer(musicCastPlayer);
		
		FunctionReference doNotAcceptAnyPlayerTypeReference = GoloUtils.createFunctionReference(this.getClass(), "acceptOnlyMusicCastPlayerType", 1);
		groupStrategyImpl.stopDetectors(doNotAcceptAnyPlayerTypeReference);
		
		Union stopDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopDetectors", stopDetectors.getClass().getName());
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());

		Tuple stopDetectorsPlayerTypes = (Tuple)stopDetectorsMembers.get(0);
		assertThat(stopDetectorsPlayerTypes, contains(musicCastPlayerType));

		assertEquals(1, processedEvents.size());
	}

	public static Object acceptOnlyMusicCastPlayerType(Object playerType) {
		return ((PlayerTypes)playerType).getIsMusicCast();
	}
	
	@Test
	public void whenStoppingOnlyBluOSMonitorOnlyBluOSMonitorMustBeStopped() throws Throwable {
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);

		Player musicCastPlayer = Player.createMockedPlayer("MusicCastPlayer", musicCastPlayerType);
		groupStrategyImpl.addPlayer(musicCastPlayer);
		
		FunctionReference acceptOnlyBluOsPlayerReference = GoloUtils.createFunctionReference(this.getClass(), "acceptOnlyBlueOsPlayer", 1);
		groupStrategyImpl.stopMonitors(acceptOnlyBluOsPlayerReference);
		
		Union stopMonitors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopMonitors", stopMonitors.getClass().getName());
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());

		Tuple stopMonitorsPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertThat(stopMonitorsPlayers, contains(bluOsPlayer));

		assertEquals(1, processedEvents.size());
	}

	public static Object acceptOnlyBlueOsPlayer(Object player) {
		return "BluOsPlayer".equals(((Player)player).id());
	}
	
	@Test(expected = IllegalStateException.class)	
	public void handleDetectedEventShouldThrowException() {
		groupStrategyImpl.handleDetectedEvent(null, null);
	}

	@Test(expected = IllegalStateException.class)	
	public void handleLostEventShouldThrowException() {
		groupStrategyImpl.handleLostEvent(null, null);
	}

	@Test
	public void handleInitializationEventShouldThrowException() {
		GroupEvents.InitializationEvent initializationEvent = GroupEvents.createMockedInitializationEvent();
		groupStrategyImpl.handleInitializationEvent(group, initializationEvent);

		assertEquals(1, processedEvents.size());

		Union startDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$startDetectors", startDetectors.getClass().getName());
		Tuple startDetectorsMembers = startDetectors.destruct();
		assertEquals(1, startDetectorsMembers.size());

		Tuple startDetectorsPlayerTypes = (Tuple)startDetectorsMembers.get(0);
		assertThat(startDetectorsPlayerTypes, contains(bluOsPlayerType, musicCastPlayerType));
	}
	
	@Test
	public void handlePlayingEventShouldStopAllDetectorsAndOtherMonitors() throws Throwable {
		// Create and add players to group
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		groupStrategyImpl.addPlayer(playingPlayer);

		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		groupStrategyImpl.addPlayer(idlePlayer);

		// Create PlayingEvent event and pass to handler function
		GroupEvents.PlayingEvent playingEvent = GroupEvents.createMockedPlayingEvent(playingPlayer);
		groupStrategyImpl.handlePlayingEvent(group, playingEvent);

		assertEquals(2, processedEvents.size());
		
		Union stopDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopDetectors", stopDetectors.getClass().getName());
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());

		Tuple stopDetectorsPlayerTypes = (Tuple)stopDetectorsMembers.get(0);
		assertThat(stopDetectorsPlayerTypes, containsInAnyOrder(bluOsPlayerType, musicCastPlayerType));

		Union stopMonitors = (Union)processedEvents.get(1);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopMonitors", stopMonitors.getClass().getName());
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());

		Tuple stopMonitorsPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertThat(stopMonitorsPlayers, contains(idlePlayer));
	}
	
	@Test
	public void idleEventShouldMarkPlayerAsIdleAndCallAfterIdleEventFunction() throws Throwable {
		// Create and add players to group
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
 		groupStrategyImpl.addPlayer(playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId");
		
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		groupStrategyImpl.addPlayer(idlePlayer);

		// Overwrite afterIdleEvent() function
		groupStrategyImpl.afterIdleEvent(GoloUtils.createFunctionReference(getClass(), "afterIdleEventHandler", 3));
		
		// Create PlayingEvent event and pass to handler function
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		groupStrategyImpl.handleIdleEvent(group, idleEvent);

		assertEquals(0, processedEvents.size());
		
		assertFalse(groupStrategyImpl.isPlayerInGroupPlaying());
		assertTrue(afterIdleEventCalled);
	}

	public static Object afterIdleEventHandler(Object strategyImpl, Object group, Object event) {
		afterIdleEventCalled = true;
		return null;
	}
} 