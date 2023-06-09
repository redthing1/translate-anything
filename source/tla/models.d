module tla.models;

struct ServerConfig {
    string host = "0.0.0.0";
    long port = 7430;
    string api_token = null;
}

struct TranslatorConfig {
    string source_language;
    string target_language;
    string model_path;
}

struct OptConfig {
    bool low_memory_mode = false;
}
