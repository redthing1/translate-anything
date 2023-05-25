FROM debian:bookworm-slim AS build

# install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl wget xz-utils \
    build-essential make cmake libc6-dev libcurl4 \
    git libxml2 \
    # stuff for ctranslate2 and sentencepiece
    libopenblas-dev liblapack-dev libz-dev libssl-dev libcrypto++-dev libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/* && apt autoremove -y && apt clean

# install dlang
ARG DPATH=/dlang
ARG D_VERSION=ldc-1.30.0
RUN mkdir -p ${DPATH} \
  && curl -fsS https://dlang.org/install.sh | bash -s ${D_VERSION},dub -p ${DPATH}

# copy source and run build
COPY . /src

# build
RUN cd /src \
    && . ${DPATH}/${D_VERSION}/activate \
    && dub build -b release-debug

FROM debian:bookworm-slim AS run

# install dependencies
RUN apt-get update && apt-get install -y \
    bash libc6-dev libcurl4 \
    git libxml2 \
    libopenblas liblapack libz libssl libcrypto++ libatlas-base \
    && rm -rf /var/lib/apt/lists/* && apt autoremove -y && apt clean

# copy built binaries
COPY --from=build /src/translate-anything /app/translate-anything
COPY --from=build /src/libctranslate2.so.3 /app/libctranslate2.so.3

# set up environment
ENV LD_LIBRARY_PATH=/app
ENV PATH=/app:$PATH

# run
CMD ["/app/translate-anything", "-c", "/app/config.toml"]
