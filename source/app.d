import std.stdio;
import std.conv;
import std.file;
import std.path;

import commandr;
import toml;

enum APP_VERSION = "v0.1.0";

enum DEFAULT_CONFIG_FILE = "config.toml";

void main(string[] args) {
	auto a = new Program("translate-anything", APP_VERSION).summary(
		"server for native inference of opus-mt models")
		.author("redthing1")
		.add(new Option("c", "configfile", "config file to use")
				.full("config-file").defaultValue(DEFAULT_CONFIG_FILE))
		.parse(args);

	if (!std.file.exists(a.option("configfile"))) {
		writeln("config file does not exist");
		return;
	}

	auto config_doc = parseTOML(std.file.readText(a.option("configfile")));
}
