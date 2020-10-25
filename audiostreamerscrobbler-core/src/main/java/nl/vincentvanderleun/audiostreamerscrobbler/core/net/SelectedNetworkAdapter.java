package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import lombok.Value;

@Value
public class SelectedNetworkAdapter {
	final NetworkAdapter networkAdapter;
	final NetworkAdapterAddress address;

	public IpAddress getAddress() {
		return address.getIpAddress();
	}
	
	public IpAddress getAddressForBroadcast() {
		return (address.getBroadcastAddress() != null ? address.getBroadcastAddress() : address.getIpAddress());
	}
}
