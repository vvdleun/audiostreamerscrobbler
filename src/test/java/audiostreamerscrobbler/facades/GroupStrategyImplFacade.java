package audiostreamerscrobbler.facades;

import static java.lang.invoke.MethodType.genericMethodType;

import java.util.LinkedHashMap;

import audiostreamerscrobbler.groups.BaseGroupStragegyImpl;
import audiostreamerscrobbler.mocks.Group;
import audiostreamerscrobbler.mocks.GroupEvents;
import audiostreamerscrobbler.mocks.Player;
import gololang.DynamicObject;
import gololang.FunctionReference;

public class GroupStrategyImplFacade {
	private DynamicObject groupStrategyImpl;

	private GroupStrategyImplFacade() { }
	
	public static GroupStrategyImplFacade createStrategyImplFacade(FunctionReference processEventsCallback) {
		GroupStrategyImplFacade groupStrategyImpl = new GroupStrategyImplFacade();
		groupStrategyImpl.groupStrategyImpl = (DynamicObject)BaseGroupStragegyImpl.createBaseGroupStragegyImpl(processEventsCallback);
		return groupStrategyImpl;
	}
	
	public LinkedHashMap<Object, Object> players() {
		try {
			return (LinkedHashMap<Object, Object>)groupStrategyImpl.invoker("players", genericMethodType(1)).invoke(groupStrategyImpl);
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
	
	public void handleDetectedEvent(Group group, GroupEvents event) {
		handleEvent("handleDetectedEvent", group, event);
	}
	
	public void handleLostEvent(Group group, GroupEvents event) {
		handleEvent("handleLostEvent", group, event);
	}

	public void handlePlayingEvent(Group group, GroupEvents event) {
		handleEvent("handlePlayingEvent", group, event);
	}
	
	public void handleIdleEvent(Group group, GroupEvents event) {
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
