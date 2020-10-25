package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InterfaceAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public class NetworkAdapterService {
	public Set<NetworkAdapter> getActiveNonLookbackNetworkAdapters() {
		try {
			return Collections.list(NetworkInterface.getNetworkInterfaces()).stream()
					.filter(networkInterface -> {
						try {
							return !networkInterface.isLoopback() && networkInterface.isUp();
						} catch (SocketException e) {
							return false;
						}
					})
					.map(networkInterface -> new NetworkAdapter(
							networkInterface.getName(),
							networkInterface.getDisplayName(),
							convertToNetworkAdapterAddress(networkInterface.getInterfaceAddresses())))
					.collect(Collectors.toSet());
		} catch(IOException ex) {
			return Collections.emptySet();
		}
	}
	
	private Set<NetworkAdapterAddress>convertToNetworkAdapterAddress(List<InterfaceAddress> interfaceAddresses) {
		return interfaceAddresses.stream()
				.map(interfaceAddress -> new NetworkAdapterAddress(
						convertToIpAddress(interfaceAddress.getAddress()),
						convertToIpAddress(interfaceAddress.getBroadcast())))
				.collect(Collectors.toSet());
	
	}
	
	private IpAddress convertToIpAddress(InetAddress inetAddress) {
		if(inetAddress == null) {
			return null;
		}

		return new IpAddress(
				inetAddress.getHostName(),
				inetAddress.getHostAddress(),
				inetAddress.getAddress());
	}
}
