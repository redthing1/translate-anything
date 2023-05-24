import std.stdio;

import commandr;

enum APP_VERSION = "v0.1.0";

enum DEFAULT_CONFIG_FILE = "config.toml";

void main(string[] args) {
	auto a = new Program("translate-anything", APP_VERSION).summary(
		"server for native inference of opus-mt models")
		.author("redthing1")
		.add(new Option("c", "config-file", "config file to use")
				.defaultValue(DEFAULT_CONFIG_FILE))
		.parse(args);
}
