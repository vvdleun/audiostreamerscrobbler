package nl.vincentvanderleun.audiostreamerscrobbler.player;

import static org.junit.jupiter.api.Assertions.*;

import java.util.HashMap;
import java.util.Map;

import org.junit.jupiter.api.Test;

import nl.vincentvanderleun.audiostreamerscrobbler.core.Config;

public class PlayerPlatformsConfigTests {
	@Test
	public void shouldFindPlayerPlatformsConfig() {
		// Key/values for a specific player of a player platform
		// In real life the value will be another Map<String, Object>, but with current implementation, 
		// there's nothing preventing it to be something else :-/
		Map<String, Object> players = new HashMap<>();
		players.put("some-player", "some-player-values");
		
		// Key/values for player platforms
		Map<String, Object> playerPlatforms = new HashMap<>();
		playerPlatforms.put("some-player-platform", players);

		// Root level configuration
		Map<String, Map<String, Object>> configValues = new HashMap<>();
		configValues.put("players", playerPlatforms);
				
		Config config = new Config(configValues);		
		PlayerPlatformsConfig playerPlatformsConfig = new PlayerPlatformsConfig(config);
		
		Map<String, Object> actualValues = playerPlatformsConfig.getPlayerPlatformConfig("some-player-platform");
		assertEquals("some-player-values", actualValues.get("some-player"));
	}
}
