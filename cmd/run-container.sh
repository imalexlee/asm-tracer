#!/bin/sh
docker run -it --rm --platform linux/amd64 --name=rt-container -v .:/usr/ray-tracer -w /usr/ray-tracer ray-tracer make run
