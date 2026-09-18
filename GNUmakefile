# GNUmakefile for crinit
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

CRYSTAL ?= crystal
SHARDS ?= shards
CRSTLINT ?= crstlint
AMEBA ?= /home/renich/Projects/crystal/init/app/bin/ameba
FLAW ?= /home/renich/Projects/crystal/init/app/bin/flaw

BIN_DIR := bin
TARGET := $(BIN_DIR)/crinit
SOURCES := $(shell find src -type f -name '*.cr' 2>/dev/null)
SPECS := $(shell find spec -type f -name '*.cr' 2>/dev/null)

.DEFAULT_GOAL := all

.PHONY: all build check spec lint flaw docs clean install help

all: build

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# Compile production release binary
build: $(TARGET)

$(TARGET): $(SOURCES) | $(BIN_DIR)
	@echo "==> Compiling crinit release binary..."
	$(CRYSTAL) build --release src/main.cr -o $(TARGET)

# Execute test suite
spec:
	@echo "==> Running Crystal spec test suite..."
	$(CRYSTAL) spec

# Run Ameba static analysis
lint:
	@echo "==> Running Ameba static analysis..."
	@if [ -x "$(AMEBA)" ]; then \
		$(AMEBA); \
	elif command -v ameba >/dev/null 2>&1; then \
		ameba; \
	else \
		echo "Warning: Ameba binary not found, skipping."; \
	fi

# Run Flaw security scanner
flaw:
	@echo "==> Running Flaw security scanner..."
	@if [ -x "$(FLAW)" ]; then \
		$(FLAW) scan src spec; \
	elif command -v flaw >/dev/null 2>&1; then \
		flaw scan src spec; \
	else \
		echo "Warning: Flaw binary not found, skipping."; \
	fi

# Run RST documentation linter
rstlint:
	@echo "==> Running crstlint on documentation..."
	@if command -v $(CRSTLINT) >/dev/null 2>&1; then \
		$(CRSTLINT) -r .; \
	fi

# Build Sphinx documentation
docs:
	@echo "==> Building Sphinx HTML documentation..."
	$(MAKE) -C docs html

# Run complete zero-defect verification gate
check: spec lint flaw rstlint

# Clean build outputs
clean:
	@echo "==> Cleaning build artifacts..."
	rm -rf $(BIN_DIR)
	$(MAKE) -C docs clean 2>/dev/null || true

# Install binary to user path
install: build
	@echo "==> Installing crinit to /usr/local/bin/..."
	install -m 0755 $(TARGET) /usr/local/bin/crinit

help:
	@echo "Available build targets:"
	@echo "  build   - Compile optimized release binary (default)"
	@echo "  spec    - Run Crystal specs"
	@echo "  lint    - Run Ameba static analysis"
	@echo "  flaw    - Run Flaw security scanner"
	@echo "  rstlint - Lint reStructuredText documentation"
	@echo "  docs    - Build Sphinx HTML documentation"
	@echo "  check   - Run full verification suite (spec, lint, flaw, rstlint)"
	@echo "  install - Install binary to /usr/local/bin/crinit"
	@echo "  clean   - Remove binary and build outputs"
