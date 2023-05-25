module tla.multitranslator;

import std.array;

import minlog;
import typetips;
import flant5;

import tla.models;

class MultiTranslator {
    FlanT5Generator[string] translation_generators;

    minlog.Logger log;

    this(minlog.Logger log) {
        this.log = log;
    }

    void load(TranslatorConfig translator_config) {
        auto slug = get_translation_slug(translator_config);
        auto gen = FlanT5Generator();
        log.info("loading translator for %s from %s", slug, translator_config.model_path);
        gen.load_model(translator_config.model_path);

        translation_generators[slug] = gen;
    }

    void unload_all() {
        translation_generators.clear();
    }

    string get_translation_slug(TranslatorConfig translator_config) {
        return translator_config.source_language ~ "-" ~ translator_config.target_language;
    }

    Optional!string translate(string text, string source_language, string target_language) {
        log.trace("translating from %s -> %s: %s", source_language, target_language, text);
        auto slug = source_language ~ "-" ~ target_language;
        if (slug !in translation_generators) {
            log.error("translation was requested for unknown language pair %s", slug);
            return no!string;
        }
        auto gen = translation_generators[slug];
        log.trace("using translator generator for %s", slug);

        auto gen_params = gen.default_gen_params;
        gen_params.beam_size = 6;
        gen_params.sampling_topk = 1;

        log.trace("generating translation with params: %s", gen_params);

        auto translation_output = gen.generate(text, gen_params).replace("▁", " ");
        return some(translation_output);
    }
}
