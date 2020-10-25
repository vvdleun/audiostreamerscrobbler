package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import lombok.Value;

@Value
public class NetworkAdapterAddress {
	IpAddress ipAddress;
	IpAddress broadcastAddress;
}
