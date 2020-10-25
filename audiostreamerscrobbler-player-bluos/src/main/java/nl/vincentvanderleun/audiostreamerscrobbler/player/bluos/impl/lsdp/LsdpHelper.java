package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

public class LsdpHelper {

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

}
