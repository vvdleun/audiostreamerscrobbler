package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import java.util.Arrays;

public class RawLsdpBytesParser {

	public RawLsdpMessage parseMessage(byte[] bytes) {
		int startIndex = findStartMessage(bytes);
		if (startIndex < 0) {
			return null;
		}
		
		byte[] header = parseField(startIndex, bytes);
		if(header == null) {
			return null;
		}
		startIndex += header.length;
		
		byte[] msg = parseField(startIndex, bytes);
		if(msg == null) {
			return null;
		}
		
		return new RawLsdpMessage(header, msg);
	}
	
	private int findStartMessage(byte[] bytes) {
		for (int i = 1; i < bytes.length - 4; i++) {
			if (startsWithHeader(i, bytes)) {
				return i - 1;
			}
		}
		
		return -1;
	}

	private boolean startsWithHeader(int index, byte[] bytes) {
		return (bytes[index] == 0x04C						// "L"
				&& bytes[index + 1] == 0x53					// "S"
				&& bytes[index + 2] == 0x44					// "D"
				&& bytes[index + 3] == 0x50);				// "P"
	}

	private byte[] parseField(int startIndex, byte[] bytes) {
		if (!canParseField(startIndex, bytes)) {
			return null;
		}

		return Arrays.copyOfRange(bytes, startIndex, startIndex + bytes[startIndex]);
	}

	private boolean canParseField(int startIndex, byte[] bytes) {
		int headerLength = bytes[startIndex];
		return bytes.length >= headerLength;
	}
}
