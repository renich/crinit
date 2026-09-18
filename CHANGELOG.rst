=========
Changelog
=========

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.1.0/>`_,
and this project adheres to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`_.

[0.1.0] - 2026-09-18
====================

.. rubric:: Added

- Initial prototype implementation of the pluggable scaffolding engine in pure Crystal stdlib.
- Macro-safe token replacement engine (``Crinit::TokenEngine``) preserving native ``{{ ... }}`` Crystal macro syntax.
- Multi-platform template discovery (``Crinit::TemplateResolver``) across Linux XDG, macOS Application Support, and Windows LocalAppData.
- Arbitrary directory tree mirrorer (``Crinit::TreeMirrorer``) with binary asset detection and POSIX permission preservation.
- 100% backward-compatible embedded view fallbacks for ``app`` and ``lib`` skeletons.
- Modular Sphinx documentation suite across Business, Functional, Technical, ADR, and Roadmap domains.
- Complete GNUmakefile build automation with spec, Ameba, Flaw, and crstlint quality gates.
