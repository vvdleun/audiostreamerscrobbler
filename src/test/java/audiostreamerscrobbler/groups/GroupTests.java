package audiostreamerscrobbler.groups;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import audiostreamerscrobbler.facades.GroupStrategyImplFacade;
import audiostreamerscrobbler.mocks.GoloUtils;
import audiostreamerscrobbler.mocks.PlayerStatus;
import gololang.FunctionReference;

public abstract class GroupTests {
	protected static final FunctionReference cbProcessEventFunctionReference = createFunctionReferenceToCbProcessEvent();
	protected static final List<Object> processedEvents = new ArrayList<>();
	protected final audiostreamerscrobbler.mocks.Group group = audiostreamerscrobbler.mocks.Group.createMockedGroup("Group");

	
	@SuppressWarnings("unchecked")
	protected static void markPlayerAsPlaying(Map<Object, Object> players, String playerId) {
		// Mark player as playing
		Map<Object, Object> mapPlayer = (Map<Object, Object>)players.get(playerId);
		mapPlayer.put("state", PlayerStatus.createMockedPlayingPlayerStatus());
	}

	// Callback functions

	public static Object cbProcessEvent(Object event) {
		processedEvents.add(event);
		return null;
	}

	// Helpers

	@SuppressWarnings("unchecked")
	protected static void markPlayerAsPlaying(GroupStrategyImplFacade groupStrategyImpl, String playerId) {
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
