package audiostreamerscrobbler.facades;

import static java.lang.invoke.MethodType.genericMethodType;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import audiostreamerscrobbler.groups.FixedPlayersGroupStrategy;
import audiostreamerscrobbler.mocks.Group;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import audiostreamerscrobbler.mocks.PlayerTypes;
import gololang.DynamicObject;
import gololang.FunctionReference;

public class FixedPlayersGroupStrategyFacade {
	private DynamicObject fixedPlayersGroupStrategy;

	private FixedPlayersGroupStrategyFacade() { }

	public static FixedPlayersGroupStrategyFacade createStrategyImplFacade(Map<String, List<String>> expectedPlayers, FunctionReference processEventsCallback) {
		FixedPlayersGroupStrategyFacade facade = new FixedPlayersGroupStrategyFacade();
		facade.fixedPlayersGroupStrategy = (DynamicObject)FixedPlayersGroupStrategy.createFixedPlayersGroupStrategy(expectedPlayers, processEventsCallback);
		return facade;
	}

	public Set<PlayerTypes> activePlayerTypes() {
		try {
			return (Set<PlayerTypes>)fixedPlayersGroupStrategy.invoker("activePlayerTypes", genericMethodType(1)).invoke(fixedPlayersGroupStrategy);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public List<PlayerTypes> playerTypes() {
		try {
			return (List<PlayerTypes>)fixedPlayersGroupStrategy.invoker("playerTypes", genericMethodType(1)).invoke(fixedPlayersGroupStrategy);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
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

	public void handleInitializationEvent(Group group, GroupEvents.InitializationEvent event) {
		handleEvent("handleInitializationEvent", group, event);	
	}
	
	public void handleDetectedEvent(Group group, GroupEvents.DetectedEvent event) {
		handleEvent("handleDetectedEvent", group, event);	
	}

	public void handleLostEvent(Group group, GroupEvents.LostEvent event) {
		handleEvent("handleLostEvent", group, event);	
	}
	
	public void handleIdleEvent(Group group, GroupEvents.IdleEvent event) {
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
