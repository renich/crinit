# GNUmakefile for {{name}}
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

CRYSTAL ?= crystal
CRYSTAL_FLAGS ?= --release

BIN_DIR := bin
TARGET := $(BIN_DIR)/{{name}}
SOURCES := $(shell find src -type f -name '*.cr' 2>/dev/null)
CONFIG_FILES := shard.yml GNUmakefile

.DEFAULT_GOAL := all

.PHONY: all build spec clean help

all: $(TARGET)

build: $(TARGET)

$(BIN_DIR):
	@mkdir -p $@

$(TARGET): $(SOURCES) $(CONFIG_FILES) | $(BIN_DIR)
	@echo "==> Compiling {{name}} ($@)..."
	$(CRYSTAL) build $(CRYSTAL_FLAGS) src/{{name}}.cr -o $@

spec:
	$(CRYSTAL) spec

clean:
	rm -rf $(BIN_DIR)

help:
	@echo "Available targets:"
	@echo "  all   - Build $(TARGET) only if sources changed (default)"
	@echo "  build - Alias for all"
	@echo "  spec  - Run Crystal specs"
	@echo "  clean - Remove $(BIN_DIR)"
	@echo "  help  - Show this help message"
