package nl.vincentvanderleun.audiostreamerscrobbler.player;

import java.util.Map;

import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import nl.vincentvanderleun.audiostreamerscrobbler.core.Config;

@EqualsAndHashCode
@AllArgsConstructor
public class PlayerPlatformsConfig {
	private static final String KEY_PLAYER_PLATFORMS = "players";
	
	private final Config config;
	
	@SuppressWarnings("unchecked")
	public Map<String, Object> getPlayerPlatformConfig(String playerPlatform) {
		return (Map<String, Object>)getPlayerPlatformsSection().get(playerPlatform);
	}
	
	private Map<String, Object> getPlayerPlatformsSection() {
		return (Map<String, Object>)config.getSectionValues(KEY_PLAYER_PLATFORMS);
	}
}
