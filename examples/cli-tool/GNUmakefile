# GNUmakefile for {{name}}
CRYSTAL ?= crystal

.PHONY: all build spec clean

all: build

build:
	$(CRYSTAL) build --release src/{{name}}.cr -o bin/{{name}}

spec:
	$(CRYSTAL) spec

clean:
	rm -rf bin/
