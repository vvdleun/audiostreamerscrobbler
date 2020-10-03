package nl.vincentvanderleun.audiostreamerscrobbler.app.main;

import java.io.File;

import nl.vincentvanderleun.audiostreamerscrobbler.app.AudioStreamerScrobblerApp;
import nl.vincentvanderleun.audiostreamerscrobbler.app.service.ConfigService;
import nl.vincentvanderleun.audiostreamerscrobbler.core.model.Config;

public class Main {
	
	public static void main(String[] args) throws Exception {
		System.out.println("AudioStreamerScrobbler v2.0\n");
		System.out.println("Reading configuration...");
		
		ConfigService configService = new ConfigService();
		
		try {
			File file = new File("config.json");
			Config config = configService.readConfigFile(file);
			AudioStreamerScrobblerApp app = new AudioStreamerScrobblerApp(config);
			
			app.run();
		} catch(Exception ex) {
			System.out.println("\n\n\nUNHANDLED EXCEPTIONT THROWN: " + ex.getMessage() + "\n\n");
			throw ex;
		}
	}	
}
