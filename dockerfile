FROM ubuntu:latest
MAINTAINER alex-lee

RUN apt-get update
RUN apt-get install -y make

ENV FASM_VERSION 1.73.32
RUN apt-get install -y curl && \
    curl -sL "https://flatassembler.net/fasm-$FASM_VERSION.tgz" | tar xz && \
    ln -s /fasm/fasm /bin/fasm
