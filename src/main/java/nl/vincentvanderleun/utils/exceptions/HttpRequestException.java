package nl.vincentvanderleun.utils.exceptions;

import java.io.IOException;

public class HttpRequestException extends IOException {
	private int responseCode;
	
	public HttpRequestException(int statusCode) {
		super("Unexpected HTTP result code " + statusCode);
	}
	
	public int getResponseCode() {
		return responseCode;
	}
	
	public void setResponseCode(int responseCode) {
		this.responseCode = responseCode;
	}
}