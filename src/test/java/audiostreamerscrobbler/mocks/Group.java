package audiostreamerscrobbler.mocks;

public class Group {
	private String name;

	private Group() { }
	
	public static Group createMockedGroup(String name) {
		Group mockedGroup = new Group();
		mockedGroup.name = name;
		return mockedGroup;
	}
	
	public String name() {
		return name;
	}
}
