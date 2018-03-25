package nl.vincentvanderleun.utils;

import java.util.Arrays;

/**
 *
 * @author Vincent
 */

public class ByteUtils {
	/* Unsigned Byte --> Signed Byte */

    public static byte toSignedByte(int unsignedByteValue) {
        return (byte)unsignedByteValue;
    }

    public static byte toSignedByte(String unsignedByteValue) {
        return (byte)Integer.parseInt(unsignedByteValue, 16);
    }

	/* Signed Byte --> Unsigned Byte */
	
    public static int toUnsignedByte(byte signedByteValue) {
        return signedByteValue & 0xFF;
    }

	/* Signed Byte Array --> Unsigned Byte Array */
	
    public static int[] toUnsignedByteArray(byte[] signedByteValue) {
        int[] result = new int[signedByteValue.length];
        for (int i = 0; i < signedByteValue.length; i++) {
            result[i] = toUnsignedByte(signedByteValue[i]);
        }
        return result;
    }

	/* Unsigned Byte Array --> Signed Byte Array */
	
    public static byte[] toSignedByteArray(int... unsignedByteValue) {
        byte[] result = new byte[unsignedByteValue.length];
        for (int i = 0; i < unsignedByteValue.length; i++) {
            result[i] = toSignedByte(unsignedByteValue[i]);
        }
        return result;
    }

    public static byte[] toSignedByteArray(String... unsignedByteHexValues) {
        byte[] result = new byte[unsignedByteHexValues.length];
        for (int i = 0; i < unsignedByteHexValues.length; i++) {
            result[i] = toSignedByte(unsignedByteHexValues[i]);
        }
        return result;
    }
}