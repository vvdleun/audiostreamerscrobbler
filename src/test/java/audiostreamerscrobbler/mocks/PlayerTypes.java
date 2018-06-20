package audiostreamerscrobbler.mocks;

public class PlayerTypes {
	private Boolean isBluOs;
	private Boolean isMusicCast;
	
	private PlayerTypes(Boolean isBluOs, Boolean isMusicCast) {
		this.isBluOs = isBluOs;
		this.isMusicCast = isMusicCast;
	}

	// Getters
	
	public Boolean getIsBluOs() {
		return isBluOs;
	}

	public Boolean getIsMusicCast() {
		return isMusicCast;
	}
	
	// Factory methods

	public static BluOsPlayerType createMockedBluOsPlayerType() {
		return new BluOsPlayerType();
	}

	public static MusicCastPlayerType createMockedMusicCastPlayerType() {
		return new MusicCastPlayerType();
	}
	
	// Implementation classes
	
	public static class BluOsPlayerType extends PlayerTypes {
		private BluOsPlayerType() {
			super(true, false);
		}
	}

	public static class MusicCastPlayerType extends PlayerTypes {
		private MusicCastPlayerType() {
			super(false, true);
		}
	}
}
