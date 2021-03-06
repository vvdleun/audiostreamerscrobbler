package audiostreamerscrobbler.facades;

import static java.lang.invoke.MethodType.genericMethodType;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;

import audiostreamerscrobbler.groups.BaseGroupStragegyImpl;
import audiostreamerscrobbler.mocks.Group;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import audiostreamerscrobbler.mocks.PlayerTypes;
import gololang.DynamicObject;
import gololang.FunctionReference;

public class GroupStrategyImplFacade {
	private DynamicObject groupStrategyImpl;

	protected GroupStrategyImplFacade() { }
	
	public static GroupStrategyImplFacade createStrategyImplFacade(List<PlayerTypes> playerTypes, FunctionReference processEventsCallback) {
		GroupStrategyImplFacade facade = new GroupStrategyImplFacade();
		facade.groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(playerTypes, processEventsCallback);
		return facade;
	}

	public List<PlayerTypes> playerTypes() {
		try {
			return (List<PlayerTypes>)groupStrategyImpl.invoker("playerTypes", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public Set<PlayerTypes> activePlayerTypes() {
		try {
			return (Set<PlayerTypes>)groupStrategyImpl.invoker("activePlayerTypes", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	// Setter for afterIdleEvent() function reference
	public void afterIdleEvent(FunctionReference functionReference) {
		try {
			groupStrategyImpl.invoker("afterIdleEvent", genericMethodType(2)).invoke(groupStrategyImpl, functionReference);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	public void addPlayer(Player player) {
		try {
			groupStrategyImpl.invoker("addPlayer", genericMethodType(2)).invoke(groupStrategyImpl, player);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	public void removePlayer(Player player) {
		try {
			groupStrategyImpl.invoker("removePlayer", genericMethodType(2)).invoke(groupStrategyImpl, player);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	public boolean hasPlayer(Player player) {
		try {
			return (Boolean)groupStrategyImpl.invoker("hasPlayer", genericMethodType(2)).invoke(groupStrategyImpl, player);		
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	public LinkedHashMap<Object, Object> players() {
		try {
			return (LinkedHashMap<Object, Object>)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public Set<Player> activePlayers() {
		try {
			return (Set<Player>)groupStrategyImpl.invoker("activePlayers", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public Player playerInGroupPlaying() {
		try {
			return (Player)groupStrategyImpl.invoker("playerInGroupPlaying", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	public void startAllDetectors() {
		try {
			groupStrategyImpl.invoker("startAllDetectors", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public void startDetectors(FunctionReference f) {
		try {
			groupStrategyImpl.invoker("startDetectors", genericMethodType(2)).invoke(groupStrategyImpl, f);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
	
	public void stopAllDetectors() {
		try {
			groupStrategyImpl.invoker("stopAllDetectors", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public void stopDetectors(FunctionReference f) {
		try {
			groupStrategyImpl.invoker("stopDetectors", genericMethodType(2)).invoke(groupStrategyImpl, f);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public void stopAllMonitors() {
		try {
			groupStrategyImpl.invoker("stopAllMonitors", genericMethodType(1)).invoke(groupStrategyImpl);
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}

	public void stopMonitors(FunctionReference f) {
		try {
			groupStrategyImpl.invoker("stopMonitors", genericMethodType(2)).invoke(groupStrategyImpl, f);
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

	public void handlePlayingEvent(Group group, GroupEvents.PlayingEvent event) {
		handleEvent("handlePlayingEvent", group, event);
	}
	
	public void handleIdleEvent(Group group, GroupEvents.IdleEvent event) {
		handleEvent("handleIdleEvent", group, event);	
	}
	
	private void handleEvent(String methodName, Group group, GroupEvents event) {
		try {
			groupStrategyImpl.invoker(methodName, genericMethodType(3)).invoke(groupStrategyImpl, group, event);
		} catch (RuntimeException e) {
			throw e;
		} catch (Throwable t) {
			throw new RuntimeException(t);
		}
	}
}
