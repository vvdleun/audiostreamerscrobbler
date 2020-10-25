package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.MulticastSocket;
import java.net.SocketTimeoutException;

import nl.vincentvanderleun.audiostreamerscrobbler.core.net.NetworkAdapter;
import nl.vincentvanderleun.audiostreamerscrobbler.core.net.NetworkAdapterFactory;
import nl.vincentvanderleun.audiostreamerscrobbler.core.net.SelectedNetworkAdapter;

public class LsdpService {
	private static final int LSDP_UDP_PORT = 11430;

	private final SelectedNetworkAdapter networkAdapter;
	private final LsdpQueryEncoder lsdpEncoder;
	private final LsdpHelper lsdpHelper = new LsdpHelper();
	private final LsdpAnnounceDecoder announceDecoder = new LsdpAnnounceDecoder(lsdpHelper);
	private final RawLsdpBytesParser parser = new RawLsdpBytesParser(lsdpHelper);

	public LsdpService(SelectedNetworkAdapter networkAdapter) {
		this.networkAdapter = networkAdapter;
		this.lsdpEncoder = new LsdpQueryEncoder();
	}

	public void run() throws IOException {
		try(MulticastSocket socket = new MulticastSocket(LSDP_UDP_PORT)) {
			
			System.out.println("Using address: " + networkAdapter.getAddress());
			socket.setInterface(networkAdapter.getAddress().toInetAddress());
			
			System.out.println("Using local port: " + socket.getLocalPort());

			InetAddress broadcastAddress = networkAdapter.getAddressForBroadcast().toInetAddress();
			
			System.out.println("Using broadcast address: " + broadcastAddress);
			
			byte[] lsdpQuery = lsdpEncoder.encodeQueryForBluOsPlayer();
			
			DatagramPacket lsdpQueryPacket = new DatagramPacket(
					lsdpQuery,
					lsdpQuery.length,
					broadcastAddress,
					LSDP_UDP_PORT);
			
			byte[] answerBytes = new byte[8192];
			DatagramPacket answerPacket = new DatagramPacket(answerBytes, answerBytes.length);
			
			socket.setSoTimeout(5000);
			
			while(true) {
				for(int i = 0; i < 3; i++) {
					socket.send(lsdpQueryPacket);
				}

				for(int i = 0; i < 5; i++) {
					try {
						System.out.println("Receiving message #" + i + "...");
						socket.receive(answerPacket);
						
						RawLsdpMessage rawMsg = parser.parseMessage(answerPacket.getData());
						if (lsdpHelper.getType(rawMsg) == TypeMessage.ANNOUNCE) {
							LsdpAnnounceResponse response = announceDecoder.decode(rawMsg);
							System.out.println(response);
						}
					} catch(SocketTimeoutException ex) {
						System.out.println("Exception: " + ex);
						Thread.sleep(10000);
					}
				}
				
				
			}
		} catch(Exception ex) {
			throw new RuntimeException(ex);
		}
	}
	
	public static void main(String[] args) throws IOException {
		NetworkAdapterFactory factory = new NetworkAdapterFactory();
		NetworkAdapter networkAdapter = factory.getByName("Realtek PCIe GBE Family Controller").get();
		
		SelectedNetworkAdapter selectedNetworkAdapter = new SelectedNetworkAdapter(networkAdapter, networkAdapter.getAddresses().iterator().next());
		
		LsdpService lsdpService = new LsdpService(selectedNetworkAdapter);
		
		lsdpService.run();
	}
	
}
