package nl.vincentvanderleun.audiostreamerscrobbler.app;

import java.util.ServiceLoader;
import java.util.Set;
import java.util.function.Consumer;
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
		executeOnPlayerPlatformServices(service -> {
			System.out.println("[" + service.getPlatform().getId() + "] Initializing " + service.getPlatform().getName() + " sub-system...");
			service.initialize(config);
		});
		executeOnPlayerPlatformServices(service -> {
			System.out.println("[" + service.getPlatform().getId() + "] Starting " + service.getPlatform().getName() + " sub-system...");
			service.start();	
 		});
		System.out.println("AudioStreamerScrobbler running...");
	}
	
	private void executeOnPlayerPlatformServices(Consumer<PlayerPlatformService> consumer) {
		playerPlatformServices.forEach(consumer::accept);
	}
}
