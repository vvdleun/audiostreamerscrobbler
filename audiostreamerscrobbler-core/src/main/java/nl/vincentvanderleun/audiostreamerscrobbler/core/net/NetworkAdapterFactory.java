package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import java.util.Optional;
import java.util.function.Predicate;

public class NetworkAdapterFactory {
	private final NetworkAdapterService networkAdapterService;
	
	public NetworkAdapterFactory() {
		this.networkAdapterService = new NetworkAdapterService();
	}
	
	public Optional<NetworkAdapter> getByName(String networkAdapterName) {
		return findByPredicate(adapter -> 
				networkAdapterName.equals(adapter.getName())
				|| networkAdapterName.equals(adapter.getDisplayName()));
	}
	
	private Optional<NetworkAdapter> findByPredicate(Predicate<NetworkAdapter> predicate) {
		return networkAdapterService.getActiveNonLookbackNetworkAdapters().stream()
				.filter(predicate)
				.findFirst();
	}
}
