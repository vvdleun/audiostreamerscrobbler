package nl.vincentvanderleun.audiostreamerscrobbler.app.service;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.nio.file.Files;
import java.util.Map;

import com.fasterxml.jackson.jr.ob.JSON;

import nl.vincentvanderleun.audiostreamerscrobbler.core.model.Config;

public class ConfigService {
	
	public Config readConfigFile(File file) throws IOException {
		try(Reader reader = Files.newBufferedReader(file.toPath())) {
			Map<String, Object> values = JSON.std.mapFrom(reader);

			return new Config(values);
		}
	}
}
