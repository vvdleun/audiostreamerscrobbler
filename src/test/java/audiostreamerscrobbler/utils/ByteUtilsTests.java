package audiostreamerscrobbler.utils;

import audiostreamerscrobbler.utils.ByteUtils;

import static org.junit.Assert.*;
import org.junit.Test;

public class ByteUtilsTests {

	@Test
	public void byteArrayMustBeCreatedFromHexStringArray() {
		String[] hexStringArray = { "0A", "0F", "FF" };

		byte[] actual= (byte[])ByteUtils.newByteArrayFromUnsignedByteHexStringArray(hexStringArray);
		byte[] expected = { 10, 15, -1 };
		
		assertArrayEquals(expected, actual);
	}

	@Test
	public void unsignedByteArrayMustBeCreatedFromSignedByteArray() {
		byte[] byteArray = { 00, 0x7F, (byte)0x80, (byte)0xFF };

		int[] actual = (int[])ByteUtils.newUnsignedByteArrayFromByteArray(byteArray);
		int[] expected = { 0, 127, 128, 255 };

		assertArrayEquals(expected, actual);
	}

	@Test
	public void mustConvertSignedByteToUnsignedByte() {
		assertEquals(0, (int)ByteUtils.unsignedByteFromByte(new Byte((byte)0)));
		assertEquals(127, (int)ByteUtils.unsignedByteFromByte(new Byte((byte)0x7F)));
		assertEquals(128, (int)ByteUtils.unsignedByteFromByte(new Byte((byte)0x80)));
		assertEquals(255, (int)ByteUtils.unsignedByteFromByte(new Byte((byte)0xFF)));
	}
}
