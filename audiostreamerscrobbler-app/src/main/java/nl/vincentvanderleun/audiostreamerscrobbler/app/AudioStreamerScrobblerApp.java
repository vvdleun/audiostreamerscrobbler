package nl.vincentvanderleun.audiostreamerscrobbler.app;

import java.util.ServiceLoader;
import java.util.Set;
import java.util.stream.Collectors;

import nl.vincentvanderleun.audiostreamerscrobbler.core.model.Config;
import nl.vincentvanderleun.audiostreamerscrobbler.core.model.PlayerPlatformService;

public class AudioStreamerScrobblerApp {
	private final Config config;
	private final Set<PlayerPlatformService> playerPlatformServices;
	
	public AudioStreamerScrobblerApp(Config config) {
		this.config = config;
		this.playerPlatformServices = ServiceLoader.load(PlayerPlatformService.class).stream()
				.map(provider -> provider.get())
				.collect(Collectors.toSet());
	}
	
	public void run() {
		System.out.println("Initializing players...");
		playerPlatformServices.forEach(playerPlatformService -> {
			System.out.println("Starting " + playerPlatformService.getPlatform().getName() + "...");
			playerPlatformService.initialize(config);
			playerPlatformService.start();
		});
		System.out.println("Players initialized.");
		System.out.println("AudioStreamerScrobbler running...");
	}
}
