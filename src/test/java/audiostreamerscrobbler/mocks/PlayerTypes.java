package audiostreamerscrobbler.mocks;

public class PlayerTypes {
	private Boolean isBluOs;
	private Boolean isMusicCast;
	private String playerTypeId;
	
	private PlayerTypes(String playerTypeId, Boolean isBluOs, Boolean isMusicCast) {
		this.playerTypeId = playerTypeId;
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
	
	public String playerTypeId() {
		return playerTypeId;
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
			super("BluOs", true, false);
		}
	}

	public static class MusicCastPlayerType extends PlayerTypes {
		private MusicCastPlayerType() {
			super("MusicCast", false, true);
		}
	}
}
