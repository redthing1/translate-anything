module tla.web;

import std.stdio;
import std.typecons;
import std.json;
import std.algorithm;
import std.range;

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
            Before((scope req, scope res) {
                // check api key if set
                if (app_context.api_token !is null) {
                    if ("Authorization" in req.headers) {
                        auto auth_header = req.headers["Authorization"];
                        // get bearer token
                        auto auth_parts = auth_header.split(" ");
                        if (auth_parts.length == 2 && auth_parts[0] == "Bearer") {
                            auto token = auth_parts[1];
                            if (token == app_context.api_token) {
                                // token accepted
                                return;
                            }
                        }
                    }
                    res.statusCode = HTTPStatus.unauthorized;
                    halt("no valid api token provided");
                    return;
                }
            });

            Post("/translate/:src_lang/:tgt_lang", "application/json", (scope req, scope res) {
                auto source_lang = req.params["src_lang"];
                auto target_lang = req.params["tgt_lang"];
                if ("texts" !in req.json) {
                    res.statusCode = HTTPStatus.badRequest;
                    return [
                        "error": "missing 'texts' field in request"
                    ].serializeJson;
                }
                auto request_texts = req.json["texts"].get!(Json[])
                    .map!(a => a.get!string)
                    .array;

                auto maybe_translated_texts = app_context.multi_translator
                    .translate_batch(request_texts, source_lang, target_lang);
                if (!maybe_translated_texts.has) {
                    res.statusCode = HTTPStatus.badRequest;
                    return [
                        "error": "unable to translate language pair"
                    ].serializeJson;
                }
                auto translated_texts = maybe_translated_texts.get;

                struct TranslationResponse {
                    string[] texts;
                }

                auto resp = TranslationResponse(translated_texts);
                return resp.serializeJson;
            });
        }
    }
}
