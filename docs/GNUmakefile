# GNUmakefile for Sphinx Documentation Suite
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

SPHINXBUILD ?= sphinx-build
SPHINXAUTOBUILD ?= sphinx-autobuild
CRSTLINT ?= crstlint
SOURCEDIR := .
BUILDDIR := build/dirhtml
HTMLDIR := build/html

DOC_SOURCES := $(shell find . -maxdepth 3 \( -name '*.rst' -o -name '*.py' \) 2>/dev/null)

.DEFAULT_GOAL := all

.PHONY: all dirhtml html dev check clean help

all: dirhtml

# Build clean directory HTML documentation using Sphinx dirhtml builder
dirhtml: $(BUILDDIR)/index.html

$(BUILDDIR)/index.html: $(DOC_SOURCES)
	@echo "==> Building Sphinx documentation with dirhtml builder..."
	$(SPHINXBUILD) -b dirhtml "$(SOURCEDIR)" "$(BUILDDIR)"
	@touch $@

# Alternative standard single-directory HTML builder target
html: $(HTMLDIR)/index.html

$(HTMLDIR)/index.html: $(DOC_SOURCES)
	@echo "==> Building Sphinx documentation with html builder..."
	$(SPHINXBUILD) -b html "$(SOURCEDIR)" "$(HTMLDIR)"
	@touch $@

# Development live-reload server using sphinx-autobuild
dev:
	@echo "==> Starting sphinx-autobuild live reload server..."
	$(SPHINXAUTOBUILD) -b dirhtml "$(SOURCEDIR)" "$(BUILDDIR)"

# Lint documentation files using crstlint
check:
	@echo "==> Linting reStructuredText documentation using crstlint..."
	@if command -v $(CRSTLINT) >/dev/null 2>&1; then \
		$(CRSTLINT) -r .; \
	else \
		echo "Warning: crstlint not found; skipping RST linting."; \
	fi

clean:
	@echo "==> Cleaning generated documentation build artifacts..."
	rm -rf build/

help:
	@echo "Documentation Build Targets:"
	@echo "  all     - Build dirhtml documentation if sources changed (default)"
	@echo "  dirhtml - Build clean directory HTML documentation in build/dirhtml/"
	@echo "  html    - Build standard HTML documentation in build/html/"
	@echo "  dev     - Start sphinx-autobuild live reload server"
	@echo "  check   - Run crstlint RST linter on documentation files"
	@echo "  clean   - Remove generated build/ directory"
	@echo "  help    - Show this help message"
