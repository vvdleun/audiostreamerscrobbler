package audiostreamerscrobbler.groups;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThat;

import java.util.ArrayList;
import java.util.List;

import org.junit.Before;
import org.junit.Test;

import audiostreamerscrobbler.facades.FixedPlayersGroupStrategyFacade;
import audiostreamerscrobbler.mocks.GoloUtils;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import audiostreamerscrobbler.mocks.PlayerTypes;
import gololang.FunctionReference;
import gololang.Tuple;
import gololang.Union;

public class FixedPlayersGroupStrategyTests extends GroupTests {
	private static FixedPlayersGroupStrategyFacade fixedPlayersGroupStrategy;
	private static final FunctionReference cbProcessEventFunctionReference = createFunctionReferenceToCbProcessEvent();
	private static final List<Object> processedEvents = new ArrayList<>();

	@Before
	public void before() {
		fixedPlayersGroupStrategy = FixedPlayersGroupStrategyFacade.createStrategyImplFacade(null, cbProcessEventFunctionReference);
		processedEvents.clear();
	}

	@Test
	public void handleIdleEventShouldStartIdlePlayersDetectors() throws Throwable {
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("GroupWithPlayersOfDifferentTypes");
		
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
		audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("GroupWithPlayersOfSameType");

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
		assertThat(startDetectorsPlayerTypes, containsInAnyOrder(bluOsPlayerType));
	}
	
	// Callback functions

	public static Object cbProcessEvent(Object event) {
		processedEvents.add(event);
		return null;
	}

	// Helpers
		
	private static FunctionReference createFunctionReferenceToCbProcessEvent() {
		try {
			return GoloUtils.createFunctionReference(FixedPlayersGroupStrategyTests.class, "cbProcessEvent", 1);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
}
