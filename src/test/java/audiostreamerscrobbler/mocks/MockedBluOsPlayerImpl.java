package audiostreamerscrobbler.mocks;

public class MockedBluOsPlayerImpl {
	private String name;
	private String port;
	private String model;
	private String version;
	private String macAddress;
	private String ipAddress;
	private String LSDPVersionSupposedly;
	private String host;
	
	public MockedBluOsPlayerImpl(String name, String port, String model, String version, String macAddress, String ipAddress, String lSDPVersionSupposedly, String host) {
		this.name = name;
		this.port = port;
		this.model = model;
		this.version = version;
		this.macAddress = macAddress;
		this.ipAddress = ipAddress;
		this.LSDPVersionSupposedly = lSDPVersionSupposedly;
		this.host = host;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getPort() {
		return port;
	}

	public void setPort(String port) {
		this.port = port;
	}

	public String getModel() {
		return model;
	}

	public void setModel(String model) {
		this.model = model;
	}

	public String getVersion() {
		return version;
	}

	public void setVersion(String version) {
		this.version = version;
	}

	public String getMacAddress() {
		return macAddress;
	}

	public void setMacAddress(String macAddress) {
		this.macAddress = macAddress;
	}

	public String getIpAddress() {
		return ipAddress;
	}

	public void setIpAddress(String ipAddress) {
		this.ipAddress = ipAddress;
	}

	public String getLSDPVersionSupposedly() {
		return LSDPVersionSupposedly;
	}

	public void setLSDPVersionSupposedly(String lSDPVersionSupposedly) {
		LSDPVersionSupposedly = lSDPVersionSupposedly;
	}

	public String getHost() {
		return host;
	}

	public void setHost(String host) {
		this.host = host;
	}
}
