package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class LsdpAnnounceDecoder {
	private final LsdpHelper lsdpHelper;
	
	public LsdpAnnounceDecoder(LsdpHelper lsdpHelper) {
		this.lsdpHelper = lsdpHelper;
	}
	
	public LsdpAnnounceResponse decode(RawLsdpMessage rawMsg) {
		if(lsdpHelper.getVersion(rawMsg) != 1) {
			throw new IllegalStateException("Unsupported LSDP version: " + lsdpHelper.getVersion(rawMsg));
		}
		
		if(lsdpHelper.getType(rawMsg) != TypeMessage.ANNOUNCE) {
			throw new IllegalStateException("Unsupported type: " + lsdpHelper.getRawType(rawMsg));
		}

		int index = 2;
		int fieldLength = rawMsg.getMsg()[index++];
		
		final byte[] node = Arrays.copyOfRange(rawMsg.getMsg(), index, index + fieldLength);
		index += fieldLength;

		fieldLength = rawMsg.getMsg()[index++];

		final byte[] address = Arrays.copyOfRange(rawMsg.getMsg(), index, index + fieldLength);
		index += fieldLength;
		
		final int countRecords = rawMsg.getMsg()[index++];

		List<LsdpAnnounceResponse.AnnounceRecord> records = new ArrayList<>(countRecords);
		
		for (int recordIndex = 0; recordIndex < countRecords; recordIndex++) {
			final int rawClassId = lsdpHelper.getRawClassId(rawMsg, index);
			final ClassId classId = lsdpHelper.getClassId(rawMsg, index);
			index += 2;
			
			final int txtRecordCount = rawMsg.getMsg()[index++];
			Map<String, String> values = new HashMap<>(txtRecordCount);
			
			for (int txtRecordIndex = 0; txtRecordIndex < txtRecordCount; txtRecordIndex++) {
				final int keyLength = rawMsg.getMsg()[index++];
				final byte[] keyBytes = Arrays.copyOfRange(rawMsg.getMsg(), index, index + keyLength);
				index += keyLength;

				final int valueLength = rawMsg.getMsg()[index++];
				final byte[] valueBytes = Arrays.copyOfRange(rawMsg.getMsg(), index, index + valueLength);
				index += valueLength;

				values.put(
						new String(keyBytes, StandardCharsets.UTF_8),
						new String(valueBytes, StandardCharsets.UTF_8));
			}
			
			records.add(new LsdpAnnounceResponse.AnnounceRecord(rawClassId, classId, values));
		}
		
		return new LsdpAnnounceResponse(
				node,
				"",
				address,
				"",
				records);
	}
}
