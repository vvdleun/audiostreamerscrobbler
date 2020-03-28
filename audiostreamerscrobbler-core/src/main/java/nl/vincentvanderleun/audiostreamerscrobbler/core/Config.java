package nl.vincentvanderleun.audiostreamerscrobbler.core;

import java.util.Map;

import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@AllArgsConstructor
@ToString
@EqualsAndHashCode
public class Config {
	private final Map<String, Map<String, Object>> values;
	
	public Map<String, Object> getSectionValues(String key) {
		return values.get(key);
	}
}
