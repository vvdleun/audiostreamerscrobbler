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

import java.util.LinkedHashMap;

public class BaseGroupStragegyImplTests extends GroupTests {
	private static GroupStrategyImplFacade groupStrategyImpl;
	private static boolean afterIdleEventCalled;
	
	@Before
	public void before() {
		groupStrategyImpl = GroupStrategyImplFacade.createStrategyImplFacade(cbProcessEventFunctionReference);
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
	public void allPlayersShouldBeReturned() {
		Player mockedPlayer1 = Player.createMockedPlayer("playerId1");
		groupStrategyImpl.addPlayer(mockedPlayer1);

		Player mockedPlayer2 = Player.createMockedPlayer("playerId2");
		groupStrategyImpl.addPlayer(mockedPlayer2);
		
		assertThat(groupStrategyImpl.allPlayers(), containsInAnyOrder(mockedPlayer1, mockedPlayer2));
	}

	@Test
	public void allPlayerTypesShouldBeReturned() {
		PlayerTypes bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		PlayerTypes musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
		
		Player mockedPlayer1 = Player.createMockedPlayer("BluOsPlayer1", bluOsPlayerType);
		groupStrategyImpl.addPlayer(mockedPlayer1);

		Player mockedPlayer2 = Player.createMockedPlayer("BluOsPlayer2", bluOsPlayerType);
		groupStrategyImpl.addPlayer(mockedPlayer2);

		Player mockedPlayer3 = Player.createMockedPlayer("MusicCastPlayer1", musicCastPlayerType);
		groupStrategyImpl.addPlayer(mockedPlayer3);
		
		assertThat(groupStrategyImpl.allPlayerTypes(), containsInAnyOrder(bluOsPlayerType, musicCastPlayerType));
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
	public void allDetectorsShouldBeStarted() {
		PlayerTypes bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		PlayerTypes musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
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
	public void noDetectorShouldBeStarted() throws Throwable {
		PlayerTypes bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
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
	public void allDetectorsShouldBeStopped() {
		PlayerTypes bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		PlayerTypes musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
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
	public void noDetectorShouldBeStopped() throws Throwable {
		PlayerTypes bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		FunctionReference doNotAcceptAnyPlayerTypeReference = GoloUtils.createFunctionReference(this.getClass(), "doNotAcceptAnyPlayerType", 1);
		groupStrategyImpl.stopDetectors(doNotAcceptAnyPlayerTypeReference);
		
		Union stopDetectors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopDetectors", stopDetectors.getClass().getName());
		Tuple stopDetectorsMembers = stopDetectors.destruct();
		assertEquals(1, stopDetectorsMembers.size());

		Tuple stopDetectorsPlayerTypes = (Tuple)stopDetectorsMembers.get(0);
		assertTrue(stopDetectorsPlayerTypes.isEmpty());

		assertEquals(1, processedEvents.size());
	}

	@Test
	public void allMonitorsShouldBeStopped() {
		PlayerTypes bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		PlayerTypes musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
		Player musicCastPlayer = Player.createMockedPlayer("MusicCastPlayer", musicCastPlayerType);
		groupStrategyImpl.addPlayer(musicCastPlayer);

		groupStrategyImpl.stopAllMonitors();
		
		Union stopMonitors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopMonitors", stopMonitors.getClass().getName());
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());

		Tuple stopMonitorsPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertThat(stopMonitorsPlayers, containsInAnyOrder(bluOsPlayer, musicCastPlayer));

		assertEquals(1, processedEvents.size());
	}

	@Test
	public void noMonitorsShouldBeStopped() throws Throwable {
		PlayerTypes bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player bluOsPlayer = Player.createMockedPlayer("BluOsPlayer", bluOsPlayerType);
		groupStrategyImpl.addPlayer(bluOsPlayer);
		
		FunctionReference doNotAcceptAnyPlayerReference = GoloUtils.createFunctionReference(this.getClass(), "doNotAcceptAnyPlayer", 1);
		groupStrategyImpl.stopMonitors(doNotAcceptAnyPlayerReference);
		
		Union stopMonitors = (Union)processedEvents.get(0);
		assertEquals("audiostreamerscrobbler.groups.GroupProcessEventTypes.types.GroupProcessEvents$stopMonitors", stopMonitors.getClass().getName());
		Tuple stopMonitorsMembers = stopMonitors.destruct();
		assertEquals(1, stopMonitorsMembers.size());

		Tuple stopMonitorsPlayers = (Tuple)stopMonitorsMembers.get(0);
		assertTrue(stopMonitorsPlayers.isEmpty());

		assertEquals(1, processedEvents.size());
	}

	public static Object doNotAcceptAnyPlayer(Object player) {
		return false;
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
	public void handlePlayingEventShouldStopAllDetectorsAndOtherMonitors() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("Group");

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		groupStrategyImpl.addPlayer(playingPlayer);

		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
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
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("Group");

		// Create and add players to group
		PlayerTypes.BluOsPlayerType bluOsPlayerType = PlayerTypes.createMockedBluOsPlayerType();
		Player playingPlayer = Player.createMockedPlayer("PlayingBluOsPlayerId", bluOsPlayerType);
		groupStrategyImpl.addPlayer(playingPlayer);
		markPlayerAsPlaying(groupStrategyImpl, "PlayingBluOsPlayerId");
		
		PlayerTypes.MusicCastPlayerType musicCastPlayerType = PlayerTypes.createMockedMusicCastPlayerType();
		Player idlePlayer = Player.createMockedPlayer("IdleMusicCastPlayerId", musicCastPlayerType);
		groupStrategyImpl.addPlayer(idlePlayer);

		// Overwrite afterIdleEvent() function
		groupStrategyImpl.afterIdleEvent(GoloUtils.createFunctionReference(getClass(), "afterIdleEventHandler", 3));
		
		// Create PlayingEvent event and pass to handler function
		GroupEvents.IdleEvent idleEvent = GroupEvents.createMockedIdleEvent(playingPlayer);
		groupStrategyImpl.handleIdleEvent(group, idleEvent);
		
		assertFalse(groupStrategyImpl.isPlayerInGroupPlaying());
		assertTrue(afterIdleEventCalled);

		assertEquals(0, processedEvents.size());
	}
	
	public static Object afterIdleEventHandler(Object strategyImpl, Object group, Object event) {
		afterIdleEventCalled = true;
		return null;
	}
} 