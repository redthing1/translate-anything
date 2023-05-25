
# translate-anything

translate anything! a server for native inference of opus-mt models

## usage

build image:
```sh
podman build --rm . -t "redthing1/translate-anything"
```

add configuration in `config.toml`:
```toml
[server]
port = 7430

[[translators]]
lang1 = "en"
lang2 = "ru"
path = "/models/ct2-opus-mt-en-ru-f32"
```

run container:
```sh
podman run --rm -it -p 7430:7430 -v $(pwd)/config.toml:/config.toml -v $(pwd)/models:/models redthing1/translate-anything
```

or better, compose:
```yaml
version: "3.8"

services:
  translate_anything:
    image: redthing1/translate-anything
    ports:
      - "7430:7430"
    volumes:
      - ./config.toml:/config.toml
      - ./models:/models
```

then `podman-compose up -d`.

## models

this project supports models based on the [Opus-MT](https://github.com/Helsinki-NLP/Opus-MT) architecture.

in order to convert models, use [CTranslate2](https://github.com/OpenNMT/CTranslate2)'s conversion script as follows:

```sh
ct2-transformers-converter --low_cpu_mem_usage --model Helsinki-NLP/opus-mt-ru-en --output_dir /path/to/ct2-opus-mt-ru-en-f32
```

then, copy `source.spm` from the original model to `spiece.model`.

this results in a converted model and sentencepiece tokenizer, and this model folder can be used with this project.

## api

for example:

`POST http://localhost:7430/v1/translate/en/ru`

request:
```json
{ "texts": [ "Hello, world!" ] }
```

response:
```json
{ "texts": [ "Привет, мир!" ] }
```
