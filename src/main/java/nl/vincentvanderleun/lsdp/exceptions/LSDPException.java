package nl.vincentvanderleun.lsdp.exceptions;

public class LSDPException extends RuntimeException {
	public LSDPException() {
	}
	
	public LSDPException(String reason) {
		super(reason);
	}
}