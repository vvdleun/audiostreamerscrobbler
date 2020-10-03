package nl.vincentvanderleun.audiostreamerscrobbler.core.model;

import java.util.Map;

import lombok.EqualsAndHashCode;
import lombok.RequiredArgsConstructor;
import lombok.ToString;

@RequiredArgsConstructor
@ToString
@EqualsAndHashCode
/**
 * Stores the global configuration data.
 *
 * Currently configuration is divided in multiple sections, each one having a key as String.
 * A section is stored in a Map with a key as String, while the corresponding value is returned
 * as an Object, so can be anything. It is expected that the code that reads the configuration
 * knows what types are used for each key before-hand. This construction was chosen, so that
 * each module can implement its own configuration data structures.
 * 
 * @author Vincent
 */
public class Config {
	private final Map<String, Object> values;
	
	@SuppressWarnings("unchecked")
	public Map<String, Object> getSection(String key) {
		return (Map<String, Object>)values.get(key);
	}
}
