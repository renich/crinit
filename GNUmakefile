# GNUmakefile for crinit
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

CRYSTAL ?= crystal
SHARDS ?= shards
CRSTLINT ?= crstlint
AMEBA ?= $(shell command -v ameba 2>/dev/null || [ -x /home/renich/Projects/crystal/init/app/bin/ameba ] && echo /home/renich/Projects/crystal/init/app/bin/ameba || echo bin/ameba)
FLAW ?= $(shell command -v flaw 2>/dev/null || [ -x /home/renich/Projects/crystal/init/app/bin/flaw ] && echo /home/renich/Projects/crystal/init/app/bin/flaw || echo bin/flaw)

# Compiler optimization flags (portable release defaults)
CRYSTAL_FLAGS ?= --release --no-debug

# Standard GNU directory variables
prefix ?= /usr/local
bindir ?= $(prefix)/bin
user_bindir ?= $(HOME)/.local/bin

BIN_DIR := bin
TARGET := $(BIN_DIR)/crinit
SOURCES := $(shell find src -type f -name '*.cr' 2>/dev/null)
SPECS := $(shell find spec -type f -name '*.cr' 2>/dev/null)
CONFIG_FILES := $(wildcard shard.yml shard.yaml .ameba.yml .ameba.yaml .flaw.yml .flaw.yaml) GNUmakefile

.DEFAULT_GOAL := all

.PHONY: all build check spec lint flaw rstlint docs clean install install-local strip uninstall help

# Default goal: build the binary artifact
all: $(TARGET)

# Alias for target artifact
build: $(TARGET)

$(BIN_DIR):
	@mkdir -p $@

# Compile production release binary only when sources or configurations change
$(TARGET): $(SOURCES) $(CONFIG_FILES) | $(BIN_DIR)
	@echo "==> Compiling crinit binary ($(CRYSTAL_FLAGS))..."
	$(CRYSTAL) build $(CRYSTAL_FLAGS) src/main.cr -o $@

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

# Strip binary symbols
strip: $(TARGET)
	@echo "==> Stripping symbols from $(TARGET)..."
	@strip -s $(TARGET)

# Install binary to user path ~/.local/bin
install-local: $(TARGET)
	@echo "==> Installing crinit to $(user_bindir)/crinit..."
	@install -d $(user_bindir)
	install -m 0755 $(TARGET) $(user_bindir)/crinit

# Install binary to system path /usr/local/bin
install: $(TARGET)
	@echo "==> Installing crinit to $(DESTDIR)$(bindir)/crinit..."
	@install -d $(DESTDIR)$(bindir)
	install -m 0755 $(TARGET) $(DESTDIR)$(bindir)/crinit

# Uninstall binary
uninstall:
	@echo "==> Uninstalling crinit from $(DESTDIR)$(bindir)/crinit..."
	rm -f $(DESTDIR)$(bindir)/crinit

help:
	@echo "Available build targets:"
	@echo "  all           - Compile binary only if sources changed (default)"
	@echo "  build         - Alias for all"
	@echo "  spec          - Run Crystal specs"
	@echo "  lint          - Run Ameba static analysis"
	@echo "  flaw          - Run Flaw security scanner"
	@echo "  rstlint       - Lint reStructuredText documentation"
	@echo "  docs          - Build Sphinx HTML documentation"
	@echo "  check         - Run full verification suite (spec, lint, flaw, rstlint)"
	@echo "  install-local - Install binary to $(user_bindir)/crinit"
	@echo "  install       - Install binary to $(DESTDIR)$(bindir)/crinit"
	@echo "  uninstall     - Remove installed binary from $(DESTDIR)$(bindir)/crinit"
	@echo "  clean         - Remove binary and build outputs"
	@echo "  help          - Show this help message"
