package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.stream.Collectors;

class LsdpHelper {
	private Charset DEFAULT_CHARSET = StandardCharsets.UTF_8;
	
	public String parseString(int startIndex, byte[] bytes) {
		if (!canParseCountedField(startIndex, bytes)) {
			return null;
		}

		var textBytes = parseCountedField(startIndex, bytes, false);
		
		return new String(textBytes, DEFAULT_CHARSET);
	}
	
	public byte[] parseCountedField(int startIndex, byte[] bytes, boolean includeCountByte) {
		if (!canParseCountedField(startIndex, bytes)) {
			return null;
		}


		int fromIndex = (includeCountByte ? startIndex : startIndex + 1);
		int toIndex = fromIndex + bytes[startIndex];

		return Arrays.copyOfRange(bytes, fromIndex, toIndex);
	}
	
	private boolean canParseCountedField(int startIndex, byte[] bytes) {
		int fieldLength = bytes[startIndex];
		return bytes.length >= fieldLength;
	}

	public int getVersion(RawLsdpMessage rawMsg) {
		return rawMsg.getHeader()[5];
	}
	
	public TypeMessage getType(RawLsdpMessage rawMsg) {
		switch(getRawType(rawMsg)) {
			case 0x51:	// "Q"
				return TypeMessage.QUERY_BROADCAST_RESPONSE;
			case 0x52:	// "R"
				return TypeMessage.QUERY_UNICAST_RESPONSE;
			case 0x41:	// "A"
				return TypeMessage.ANNOUNCE;
			case 0x44:	// "D"
				return TypeMessage.DELETE;
			default:
				return TypeMessage.UNKNOWN;
		}
	}
	
	public byte getRawType(RawLsdpMessage rawMsg) {
		return rawMsg.getMsg()[1];
	}
	
	public ClassId getClassId(RawLsdpMessage rawMsg, int startIndex) {
		switch(getRawClassId(rawMsg, startIndex)) {
			case 0x0001:
				return ClassId.BLUOS_PLAYER;
			case 0x0002:
				return ClassId.BLUOS_SERVER;
			case 0x0003:
				return ClassId.BLUOS_PLAYER_SECONDARY;
			case 0x0004:
				return ClassId.SOVI_MFG;
			case 0xFFFF:
				return ClassId.ALL_CLASSES;
			default:
				return ClassId.UNKOWN;
		}
	}
	
	public int getRawClassId(RawLsdpMessage rawMsg, int startIndex) {
		return (rawMsg.getMsg()[startIndex] << 8)
				+ rawMsg.getMsg()[startIndex + 1];
	}

	public int[] toUnsignedBytes(byte[] bytes) {
		int[] unsignedBytes = new int[bytes.length];
		for (int i = 0; i < bytes.length; i++) {
			unsignedBytes[i] = bytes[i] & 0xFF;
		}
		return unsignedBytes;
	}

	public String formatAddress(int[] unsignedBytes) {
		if(unsignedBytes.length != 4) {
			// Assume non-IP4 address are always a hex string
			return formatAsHexString(unsignedBytes);
		}
		
		return Arrays.stream(unsignedBytes)
				.mapToObj(String::valueOf)
				.collect(Collectors.joining(":"));
				
	}
	
	public String formatAsHexString(int[] unsignedBytes) {
		return Arrays.stream(unsignedBytes)
				.mapToObj(this::toHex)
				.collect(Collectors.joining(":"));
	}
	
	private String toHex(int unsignedByte) {
		String hexString = Integer.toHexString(unsignedByte);
		if(unsignedByte < 0x10) {
			return "0" + hexString;
		}
		return hexString;
	}	
}
