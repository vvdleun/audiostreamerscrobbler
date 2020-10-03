package nl.vincentvanderleun.audiostreamerscrobbler.app.service;

import static org.junit.jupiter.api.Assertions.*;

import java.io.File;
import java.util.Map;

import org.junit.jupiter.api.Test;

import nl.vincentvanderleun.audiostreamerscrobbler.core.model.Config;

public class ConfigServiceTest {
	private ConfigService configService = new ConfigService();
	
	@Test
	public void testReadConfigFile() throws Exception {
		File file = new File(this.getClass().getResource("/dummy_config.json").getFile());		
		Config config = configService.readConfigFile(file);
		
		Map<String, Object> actual = config.getSection("section1");
		
		assertTrue((Boolean)actual.get("dummyValue"));

		assertTrue(((Map<String, Object>)config.getSection("section2")).isEmpty());
	}
}
