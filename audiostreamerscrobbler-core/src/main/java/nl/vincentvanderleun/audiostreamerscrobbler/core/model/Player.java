package nl.vincentvanderleun.audiostreamerscrobbler.core.model;

public interface Player {
	String getId();
	String getName();
	boolean isEnabled();
	String getHost();
	PlayerPlatform getPlatform();
}
