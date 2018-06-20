package audiostreamerscrobbler.mocks;

public class Player {
	private String id;
	private PlayerTypes playerType;
	
	private Player() { }

	public static Player createMockedPlayer(String playerId, PlayerTypes playerType) {
		Player mockedPlayer = createMockedPlayer(playerId);
		mockedPlayer.playerType = playerType;
		return mockedPlayer;
	}

	public static Player createMockedPlayer(String playerId) {
		Player mockedPlayer = new Player();
		mockedPlayer.id = playerId;

		return mockedPlayer;
	}

	// Getters
	
	public String id() {
		return id;
	}
	
	public PlayerTypes playerType() {
		return playerType;
	}
}
