module nl.vincentvanderleun.audiostreamerscrobbler.player.bluos {
	requires static lombok;

	requires transitive nl.vincentvanderleun.audiostreamerscrobbler.core;

	exports nl.vincentvanderleun.audiostreamerscrobbler.player.bluos;
	
	provides nl.vincentvanderleun.audiostreamerscrobbler.core.model.PlayerPlatformService
	with nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.BluOsPlayerPlatformService;
}