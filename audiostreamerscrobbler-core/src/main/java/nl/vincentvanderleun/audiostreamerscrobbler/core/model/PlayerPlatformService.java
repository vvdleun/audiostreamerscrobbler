package nl.vincentvanderleun.audiostreamerscrobbler.core.model;

public interface PlayerPlatformService {
	PlayerPlatform getPlatform();
	void initialize(Config config);
	void start();
	void stop();
}
