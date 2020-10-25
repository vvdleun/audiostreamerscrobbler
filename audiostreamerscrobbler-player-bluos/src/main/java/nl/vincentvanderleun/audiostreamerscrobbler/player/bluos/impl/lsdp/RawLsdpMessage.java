package nl.vincentvanderleun.audiostreamerscrobbler.player.bluos.impl.lsdp;

import lombok.Value;

@Value
public class RawLsdpMessage {
	byte[] header;
	byte[] msg;
}
