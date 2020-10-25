package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import org.junit.jupiter.api.Test;

public class NetworkAdapterServiceTest {
	private NetworkAdapterService networkAdapterService = new NetworkAdapterService();
	
	@Test
	public void shouldListNetwork() {
		for(NetworkAdapter adapter : networkAdapterService.getActiveNonLookbackNetworkAdapters()) {
			System.out.println("Name             : " + adapter.getName());
			System.out.println("Display Name     : " + adapter.getDisplayName());
			System.out.println("\nNetwork addresses:");
			for(NetworkAdapterAddress adapterAddress : adapter.getAddresses()) {
				System.out.println(" Ip Address       : "  + adapterAddress.getIpAddress());
				System.out.println(" Broadcast address: "  + adapterAddress.getBroadcastAddress() + "\n\n");
				
			}
		}
	}
	
}
