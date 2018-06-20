package audiostreamerscrobbler.mocks;

public class PlayerStatus {
	private Boolean isIdle;
	private Boolean isPlaying;
	
	private PlayerStatus(Boolean isIdle, Boolean isPlaying) {
		this.isIdle = isIdle;
		this.isPlaying = isPlaying;
	}

	// Getters

	public Boolean getIsIdle() {
		return isIdle;
	}

	public Boolean getIsPlaying() {
		return isPlaying;
	}

	// Factory classes
	
	public static Idle createIdlePlayerStatus() {
		return new Idle();
	}

	public static Playing createPlayingPlayerStatus() {
		return new Playing();
	}
	
	// Implementation classes
	
	public static class Idle extends PlayerStatus {
		private Idle() {
			super(true, false);
		}
	}
	
	public static class Playing extends PlayerStatus {
		private Playing() {
			super(false, true);
		}
	}
}
