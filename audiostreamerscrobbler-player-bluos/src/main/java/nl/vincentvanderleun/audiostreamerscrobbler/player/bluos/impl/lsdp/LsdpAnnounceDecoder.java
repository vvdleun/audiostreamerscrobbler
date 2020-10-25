package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import java.util.ArrayList;
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

		final int[] node = lsdpHelper.toUnsignedBytes(lsdpHelper.parseCountedField(index, rawMsg.getMsg(), false));
		index += node.length + 1;

		final int[] address = lsdpHelper.toUnsignedBytes(lsdpHelper.parseCountedField(index, rawMsg.getMsg(), false));
		index += address.length + 1;

		List<LsdpAnnounceResponse.AnnounceRecord> announceRecords = readTextRecords(rawMsg, index);

		return new LsdpAnnounceResponse(
				node,
				lsdpHelper.formatAsHexString(node),
				address,
				lsdpHelper.formatAddress(address),
				announceRecords);
	}
	
	private List<LsdpAnnounceResponse.AnnounceRecord> readTextRecords(RawLsdpMessage rawMsg, int startIndex) {
		int index = startIndex;
		
		final int countRecords = rawMsg.getMsg()[index++];

		List<LsdpAnnounceResponse.AnnounceRecord> records = new ArrayList<>(countRecords);
		
		for (int recordIndex = 0; recordIndex < countRecords; recordIndex++) {
			final int rawClassId = lsdpHelper.getRawClassId(rawMsg, index);
			final ClassId classId = lsdpHelper.getClassId(rawMsg, index);
			index += 2;
			
			final int txtRecordCount = rawMsg.getMsg()[index++];
			final Map<String, String> values = new HashMap<>(txtRecordCount);
			
			for (int txtRecordIndex = 0; txtRecordIndex < txtRecordCount; txtRecordIndex++) {
				final String key = lsdpHelper.parseString(index, rawMsg.getMsg());
				index += key.length() + 1;
	
				final String value = lsdpHelper.parseString(index, rawMsg.getMsg());
				index += value.length() + 1;
	
				values.put(key, value);
			}
		
			records.add(new LsdpAnnounceResponse.AnnounceRecord(rawClassId, classId, values));
		}
		return records;
	}
}
