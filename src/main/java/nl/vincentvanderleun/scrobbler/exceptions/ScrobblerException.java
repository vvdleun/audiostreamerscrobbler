package nl.vincentvanderleun.scrobbler.exceptions;

public class ScrobblerException extends RuntimeException {
	private boolean shouldRetryLater;

	public ScrobblerException(String reason, boolean shouldRetryLater) {
		this(new RuntimeException(reason), shouldRetryLater);
	}
	
	public ScrobblerException(Exception ex, boolean shouldRetryLater) {
		super(ex);
		this.shouldRetryLater = shouldRetryLater;
	}
	
	public boolean getShouldRetryLater() {
		return shouldRetryLater;
	}
	
	public void setShouldRetryLater(boolean shouldRetryLater) {
		this.shouldRetryLater = shouldRetryLater;
	}
}
