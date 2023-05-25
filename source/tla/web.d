module tla.web;

import std.stdio;
import std.typecons;
import std.json;

import vibe.d;
import vibrant.d;
import mir.ser.json : serializeJson;
import minlog;
import typetips;

import tla.multitranslator;
import tla.global;

void vibrant_web(T)(T vib) {
    with (vib) {
        with (Scope("/v1")) {
            // POST /v1/translate/{src_lang}/{tgt_lang}
            Post("/translate/:src_lang/:tgt_lang", "application/json", (scope req, scope res) {
                auto source_lang = req.params["src_lang"];
                auto target_lang = req.params["tgt_lang"];
                if ("text" !in req.json) {
                    // res.status = HTTPStatus.badRequest;
                    // return "missing 'text' field in request";
                    return format(`{"error": "missing 'text' field in request"}`);
                }
                auto request_text = req.json["text"].get!string;

                auto maybe_translated_text = app_context.multi_translator.translate(request_text, source_lang, target_lang);
                if (!maybe_translated_text.has) {
                    // res.status = HTTPStatus.badRequest;
                    // return "unable to translate language pair";
                    return format(`{"error": "unable to translate language pair"}`);
                }
                auto translated_text = maybe_translated_text.get;

                struct TranslationResponse {
                    string text;
                }

                auto resp = serializeJson(TranslationResponse(translated_text));
                return resp.serializeJson;
            });
        }
    }
}
