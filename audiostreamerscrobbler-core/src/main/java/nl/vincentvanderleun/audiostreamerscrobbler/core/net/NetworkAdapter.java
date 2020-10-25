package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import java.util.Set;

import lombok.Value;

@Value
public class NetworkAdapter {
	private String name;
	private String displayName;
	private Set<NetworkAdapterAddress> addresses;
}
