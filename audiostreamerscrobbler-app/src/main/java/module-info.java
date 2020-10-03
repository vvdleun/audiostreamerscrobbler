module nl.vincentvanderleun.audiostreamerscrobbler.app {
	exports nl.vincentvanderleun.audiostreamerscrobbler.app.main;

	requires com.fasterxml.jackson.jr.ob;

	requires nl.vincentvanderleun.audiostreamerscrobbler.core;
	
	uses nl.vincentvanderleun.audiostreamerscrobbler.core.model.PlayerPlatformService;
}