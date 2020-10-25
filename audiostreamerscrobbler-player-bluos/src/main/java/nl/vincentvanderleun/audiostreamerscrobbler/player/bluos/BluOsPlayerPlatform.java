package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos;

import nl.vincentvanderleun.audiostreamerscrobbler.core.model.PlayerPlatform;

public class BluOsPlayerPlatform implements PlayerPlatform {

	@Override
	public String getId() {
		return "bluos";
	}

	@Override
	public String getName() {
		return "Bluesound/BluOS";
	}

}
