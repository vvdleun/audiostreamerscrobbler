package audiostreamerscrobbler.facades;

import static java.lang.invoke.MethodType.genericMethodType;

import java.util.LinkedHashMap;
import java.util.List;

import audiostreamerscrobbler.groups.FixedPlayersGroupStrategy;
import audiostreamerscrobbler.mocks.Group;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import gololang.DynamicObject;
import gololang.FunctionReference;

public class FixedPlayersGroupStrategyFacade {
	private DynamicObject fixedPlayersGroupStrategy;

	private FixedPlayersGroupStrategyFacade() { }

	public static FixedPlayersGroupStrategyFacade createStrategyImplFacade(List<String> playerIds, FunctionReference processEventsCallback) {
		FixedPlayersGroupStrategyFacade facade = new FixedPlayersGroupStrategyFacade();
		facade.fixedPlayersGroupStrategy = (DynamicObject)FixedPlayersGroupStrategy.createFixedPlayersGroupStrategy(playerIds, processEventsCallback);
		return facade;
	}

	public void addPlayer(Player player) {
		try {
			fixedPlayersGroupStrategy.invoker("addPlayer", genericMethodType(2)).invoke(fixedPlayersGroupStrategy, player);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public LinkedHashMap<Object, Object> players() {
		try {
			return (LinkedHashMap<Object, Object>)fixedPlayersGroupStrategy.invoker("players", genericMethodType(1)).invoke(fixedPlayersGroupStrategy);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	public void afterIdleEvent() {
		try {
			fixedPlayersGroupStrategy.invoker("afterIdleEvent", genericMethodType(1)).invoke(fixedPlayersGroupStrategy);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public void handleIdleEvent(Group group, GroupEvents event) {
		handleEvent("handleIdleEvent", group, event);	
	}

	private void handleEvent(String methodName, Group group, GroupEvents event) {
		try {
			fixedPlayersGroupStrategy.invoker(methodName, genericMethodType(3)).invoke(fixedPlayersGroupStrategy, group, event);
		} catch (RuntimeException e) {
			throw e;
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
}
