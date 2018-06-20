package audiostreamerscrobbler.mocks;

public class GroupEvents {
	private Boolean isDetectedEvent;
	private Boolean isLostEvent;
	private Boolean isPlayingEvent;
	private Boolean isIdleEvent;
	
	private GroupEvents(Boolean isDetectedEvent, Boolean isLostEvent, Boolean isPlayingEvent, Boolean isIdleEvent) {
		this.isDetectedEvent = isDetectedEvent;
		this.isLostEvent = isLostEvent;
		this.isPlayingEvent = isPlayingEvent;
		this.isIdleEvent = isIdleEvent;
	}

	// Getters
	
	public Boolean isDetectedEvent() {
		return isDetectedEvent;
	}

	public Boolean isLostEvent() {
		return isLostEvent;
	}

	public Boolean isPlayingEvent() {
		return isPlayingEvent;
	}


	public Boolean isIdleEvent() {
		return isIdleEvent;
	}

	// Factory methods

	public static DetectedEvent createDetectedEvent(Object player) {
		return new DetectedEvent(player);
	}
	
	public static LostEvent createLostEvent(Object player) {
		return new LostEvent(player);
	}

	public static PlayingEvent createPlayingEvent(Object player) {
		return new PlayingEvent(player);
	}

	public static IdleEvent createIdleEvent(Object player) {
		return new IdleEvent(player);
	}

	// Implementation classes
	
	public static class DetectedEvent extends GroupEvents {
		private Object player;
		
		private DetectedEvent(Object player) {
			super(true, false, false, false);
			this.player = player;
		}
		
		public Object player() {
			return player;
		}
		
	}

	public static class LostEvent extends GroupEvents {
		private Object player;
		
		private LostEvent(Object player) {
			super(false, true, false, false);
			this.player = player;
		}
		
		public Object player() {
			return player;
		}
	}

	public static class PlayingEvent extends GroupEvents {
		private Object player;
		
		private PlayingEvent(Object player) {
			super(false, false, true, false);
			this.player = player;
		}
		
		public Object player() {
			return player;
		}
	}

	public static class IdleEvent extends GroupEvents {
		private Object player;
		
		private IdleEvent(Object player) {
			super(false, false, false, true);
			this.player = player;
		}
		
		public Object player() {
			return player;
		}
	}
}
