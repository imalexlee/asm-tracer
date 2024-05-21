all: entry

run:  entry
	./out/ray-tracer

entry: src/entry.s
	fasm src/entry.s out/ray-tracer	
	chmod +x out/ray-tracer


