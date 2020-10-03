package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos;

import nl.vincentvanderleun.audiostreamerscrobbler.core.model.Config;
import nl.vincentvanderleun.audiostreamerscrobbler.core.model.PlayerPlatform;
import nl.vincentvanderleun.audiostreamerscrobbler.core.model.PlayerPlatformService;

public class BluOsPlayerPlatformService implements PlayerPlatformService {
	private static final BluOsPlayerPlatform PLAYER_PLATFORM = new BluOsPlayerPlatform();
	
	@Override
	public PlayerPlatform getPlatform() {
		return PLAYER_PLATFORM;
	}

	@Override
	public void initialize(Config config) {
		System.out.println("* Initializing " + PLAYER_PLATFORM.getName() + "...");
	}

	@Override
	public void start() {
	}

	@Override
	public void stop() {
	}
}
