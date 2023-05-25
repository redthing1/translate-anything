module tla.models;

struct ServerConfig {
    string host = "0.0.0.0";
    long port = 7430;
}

struct TranslatorConfig {
    string source_language;
    string target_language;
    string model_path;
}

struct OptConfig {
    bool keep_all_loaded = true;
}
