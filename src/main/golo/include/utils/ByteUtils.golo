module audiostreamerscrobbler.utils.ByteUtils

import nl.vincentvanderleun.utils.ByteUtils

import java.util.Arrays

function newByteArrayFromUnsignedByteHexStringArray = |hexStringArray| {
	let buffer = newTypedArray(String.class, hexStringArray: length())
	for (var i = 0, i < hexStringArray: length(), i = i + 1) {
		buffer: set(i, hexStringArray: get(i))
	}
	return ByteUtils.toSignedByteArray(buffer)
}

function newUnsignedByteArrayFromByteArray = |byteArray| {
	return ByteUtils.toUnsignedByteArray(byteArray)
}
 
function unsignedByteFromByte = |b| {
	return ByteUtils.toUnsignedByte(b)
}