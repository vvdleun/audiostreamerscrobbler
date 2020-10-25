package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import java.util.Arrays;

public class LsdpQueryEncoder {
	private static final byte[] LSDP_QUERY_TEMPLATE;
	
	static {
		LSDP_QUERY_TEMPLATE = new byte[11];
		
		LSDP_QUERY_TEMPLATE[0] = 0x06;						// Length header
		LSDP_QUERY_TEMPLATE[1] = 0x4C;						// "L"
		LSDP_QUERY_TEMPLATE[2] = 0x53;						// "S"
		LSDP_QUERY_TEMPLATE[3] = 0x44;						// "D"
		LSDP_QUERY_TEMPLATE[4] = 0x50;						// "P"
		LSDP_QUERY_TEMPLATE[5] = 0x01;						// Version 1 protocol
		LSDP_QUERY_TEMPLATE[6] = 0x05;						// Query length
		LSDP_QUERY_TEMPLATE[7] = 0x51;						// "Q" (Standard Query for broadcast response)
		LSDP_QUERY_TEMPLATE[8] = 0x01;						// Classes to query
		LSDP_QUERY_TEMPLATE[9] = 0x00;						// Class ID "BluOS Player" high byte
		LSDP_QUERY_TEMPLATE[10] = 0x01;						// Class ID "BluOS Player" low byte
	}
	
	public byte[] encodeQueryForBluOsPlayer() {
		return Arrays.copyOf(LSDP_QUERY_TEMPLATE, LSDP_QUERY_TEMPLATE.length);
	}

}
