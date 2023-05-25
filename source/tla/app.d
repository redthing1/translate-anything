module tla.app;

import std.stdio;
import std.conv;
import std.file;
import std.path;
import std.algorithm : min;

import vibe.d;
import vibrant.d;
import commandr;
import toml;
import minlog;

import tla.models;
import tla.web;
import tla.multitranslator;

enum APP_VERSION = "v0.1.0";

enum DEFAULT_CONFIG_FILE = "config.toml";

void main(string[] args) {
	auto a = new Program("translate-anything", APP_VERSION).summary(
		"server for native inference of opus-mt models")
		.author("redthing1")
		.add(new Option("c", "configfile", "config file to use")
				.full("config-file").defaultValue(DEFAULT_CONFIG_FILE))
		.add(new Flag("v", "verbose", "turns on more verbose output").repeating)
		.parse(args);

	auto verbose_count = min(a.occurencesOf("verbose"), 2);
	auto logger_verbosity = (Verbosity.info.to!int + verbose_count).to!Verbosity;

	auto log = minlog.Logger(logger_verbosity);
	log.use_colors = true;
	log.meta_timestamp = false;
	log.source = "tla";

	if (!std.file.exists(a.option("configfile"))) {
		writeln("config file does not exist");
		return;
	}

	auto config_doc = parseTOML(std.file.readText(a.option("configfile")));

	if ("server" !in config_doc) {
		writeln("configuration is missing [server] section");
		return;
	}
	auto server_table = config_doc["server"];
	auto server_host = server_table["host"].str;
	auto server_port = server_table["port"].integer;

	if ("translators" !in config_doc) {
		writeln("configuration is missing [[translators]] array");
		return;
	}
	auto translators_tables = config_doc["translators"].array;
	TranslatorConfig[] translator_configs;
	foreach (translator_table; translators_tables) {
		auto source_lang = translator_table["lang1"].str;
		auto target_lang = translator_table["lang2"].str;
		auto model_path = translator_table["path"].str;
		translator_configs ~= TranslatorConfig(source_lang, target_lang, model_path);
	}

	log.info("configured translators: %s", translator_configs);

	// load translators one by one
	auto multi_translator = new MultiTranslator();
	foreach (translator_config; translator_configs) {
		log.info("loading translator %s", translator_config);
		multi_translator.load(translator_config);
	}

	log.info("starting server on %s:%s", server_host, server_port);

	auto settings = new HTTPServerSettings;
	settings.hostName = server_host;
	settings.port = cast(ushort) server_port;

	auto vib = Vibrant(settings);
	vibrant_web(vib);

	// listenHTTP is called automatically
	runApplication();

	scope (exit)
		vib.Stop();
}