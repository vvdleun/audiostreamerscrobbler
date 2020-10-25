package nl.vincentvanderleun.audiostreamerscrobbler.core.net;

import java.io.IOException;
import java.net.MulticastSocket;

public class MultiCastService {
	private final MulticastSocket multiCastSocket;
	
	public MultiCastService(int port) throws IOException {
		this.multiCastSocket = new MulticastSocket(port);
		
	}
}
