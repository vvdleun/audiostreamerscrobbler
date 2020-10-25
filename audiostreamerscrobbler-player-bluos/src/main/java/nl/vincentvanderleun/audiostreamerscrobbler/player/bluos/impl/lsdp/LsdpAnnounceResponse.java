package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import java.util.List;
import java.util.Map;

import lombok.Value;

@Value
public class LsdpAnnounceResponse {
	byte[] nodeRaw;
	String node;
	byte[] addressRaw;
	String address;
	List<AnnounceRecord> records;
		
	@Value
	public static class AnnounceRecord {
		int classIdRaw;
		ClassId classId;
		Map<String, String> textRecords;
	}
}
