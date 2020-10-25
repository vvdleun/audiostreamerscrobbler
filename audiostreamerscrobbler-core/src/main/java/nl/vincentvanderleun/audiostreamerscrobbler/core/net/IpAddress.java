package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import java.io.IOException;
import java.net.InetAddress;

import lombok.Value;

@Value
public class IpAddress {
	String hostName;
	String hostAddress;
	byte[] rawAddress;
	
	public InetAddress toInetAddress() {
		try {
			return InetAddress.getByAddress(rawAddress);
		} catch(IOException ex) {
			throw new RuntimeException(ex);
		}
	}
}
