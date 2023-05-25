module tla.multitranslator;

import std.stdio;
import std.string;
import std.array;
import std.exception : enforce;

import minlog;
import typetips;
import flant5;

import tla.models;

class MultiTranslator {
    TranslatorConfig[] translator_configs;
    FlanT5Generator*[string] translation_generators;
    bool keep_all_loaded = true;

    minlog.Logger log;

    this(minlog.Logger log, bool keep_all_loaded) {
        this.log = log;
        this.keep_all_loaded = keep_all_loaded;
    }

    void register_translators(TranslatorConfig[] translator_configs) {
        this.translator_configs = translator_configs;
    }

    void load_all_translators() {
        if (!keep_all_loaded) {
            // we ignore this, because we load on demand
            return;
        }
        foreach (translator_config; translator_configs) {
            load_and_cache(translator_config);
        }
    }

    FlanT5Generator* load_generator(TranslatorConfig translator_config) {
        auto gen = new FlanT5Generator();
        auto slug = get_translation_slug(translator_config);
        log.info("loading translator for %s from %s", slug, translator_config.model_path);
        gen.load_model(translator_config.model_path);
        return gen;
    }

    void load_and_cache(TranslatorConfig translator_config) {
        auto gen = load_generator(translator_config);
        auto slug = get_translation_slug(translator_config);
        translation_generators[slug] = gen;
    }

    void unload_all() {
        translation_generators.clear();
    }

    string get_translation_slug(TranslatorConfig translator_config) {
        return translator_config.source_language ~ "-" ~ translator_config.target_language;
    }

    Optional!TranslatorConfig get_translator_config_for(string source_language, string target_language) {
        foreach (translator_config; translator_configs) {
            if (translator_config.source_language == source_language && translator_config.target_language == target_language) {
                return some(translator_config);
            }
        }
        return no!TranslatorConfig;
    }

    FlanT5Generator* get_translator_for(string source_language, string target_language) {
        auto slug = source_language ~ "-" ~ target_language;
        if (slug !in translation_generators) {
            // check if the translator is registered
            auto maybe_translator_config = get_translator_config_for(source_language, target_language);
            if (!maybe_translator_config.has) {
                log.error("translation was requested for unknown language pair %s", slug);
                return null;
            }

            if (!keep_all_loaded) {
                // if on-demand loading is enabled, load it
                auto gen = load_generator(maybe_translator_config.get);
                return gen;
            } else {
                enforce(0, "should never have translator config registered "
                        ~ "but not in cache, when on-demand loading is disabled");
            }
        }
        // it's cached, so just return it
        return translation_generators[slug];
    }

    Optional!(string[]) translate_batch(string[] texts, string source_language, string target_language) {
        auto maybe_gen = get_translator_for(source_language, target_language);
        if (maybe_gen is null)
            return no!(string[]);
        auto gen = maybe_gen;

        auto gen_params = gen.default_gen_params;
        gen_params.beam_size = 6;
        gen_params.sampling_topk = 1;

        log.trace("translating from %s -> %s: %s", source_language, target_language, texts);
        string[] output_texts;
        foreach (text; texts) {
            text = text.strip();

            auto translation_output = gen.generate(text, gen_params).replace("▁", " ").strip();
            output_texts ~= translation_output;
        }
        log.trace("translated (%s -> %s): %s -> %s", source_language, target_language, texts, output_texts);

        return some(output_texts);
    }
}
