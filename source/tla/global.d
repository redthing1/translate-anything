module tla.global;

import minlog;
import tla.multitranslator;

struct AppContext {
    minlog.Logger logger;
    MultiTranslator multi_translator;
    string api_token;
}

AppContext app_context;