package nl.vincentvanderleun.scrobbler.bluos;

public class BluOsParsedStatus {
	private boolean success;
	private String etag;
	private String album;
	private String artist;
	private String name;
	private String state;
	private String service;
	private int secs;
	private int totlen;

	public boolean isSuccess() {
		return success;
	}

	public void setSuccess(boolean success) {
		this.success = success;
	}

	public String getEtag() {
		return etag;
	}

	public void setEtag(String etag) {
		this.etag = etag;
	}

	public String getAlbum() {
		return album;
	}

	public void setAlbum(String album) {
		this.album = album;
	}

	public String getArtist() {
		return artist;
	}

	public void setArtist(String artist) {
		this.artist = artist;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getState() {
		return state;
	}

	public void setState(String state) {
		this.state = state;
	}

	public String getService() {
		return service;
	}

	public void setService(String service) {
		this.service = service;
	}

	public int getSecs() {
		return secs;
	}

	public void setSecs(int secs) {
		this.secs = secs;
	}

	public int getTotlen() {
		return totlen;
	}

	public void setTotlen(int totlen) {
		this.totlen = totlen;
	}
}
