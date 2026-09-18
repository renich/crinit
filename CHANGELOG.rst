=========
Changelog
=========

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.1.0/>`_,
and this project adheres to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`_.

[0.1.0] - 2026-09-18
====================

.. rubric:: Added

- Pluggable scaffolding engine in pure Crystal stdlib without external shard dependencies.
- Macro-safe token replacement engine (``Crinit::TokenEngine``) preserving native ``{{ ... }}`` and ``{% ... %}`` Crystal macro syntax with ``\{{ ... \}}`` escaping.
- Multi-platform template discovery (``Crinit::TemplateResolver``) across Linux XDG, macOS Application Support, Windows LocalAppData, and binary-relative ``$ORIGIN`` paths.
- Directory tree mirrorer (``Crinit::TreeMirrorer``) with binary asset byte-for-byte passthrough and POSIX executable bit (``0o755``) preservation.
- 100% backward-compatible embedded view fallbacks for ``app`` and ``lib`` skeletons.
- 4-tier remote asset pipeline (``Crinit::AssetFetcher``) supporting content-addressed caching (Tier 1), integrity-pinned HTTP fetching (Tier 2), bundled offline fallback (Tier 3), and graceful ``.todo`` placeholder degradation (Tier 4).
- Content-addressed local filesystem asset cache (``Crinit::CacheStore``) keyed by SHA-256 digests.
- Dual manifest format support accepting both ``template.yml`` and ``template.yaml``.
- Production reference templates under ``examples/`` (``enterprise-service``, ``kemal-web``, and ``cli-tool``).
- CLI flags for asset resolution and caching: ``--cache-dir``, ``--no-cache``, ``--offline``, and ``--offline-fallback``.
- Modular Sphinx documentation suite across Business, Functional, Technical, ADR, Roadmap, and Audit domains.
- Complete GNUmakefile build automation with spec, Ameba, Flaw, and crstlint quality gates.

.. rubric:: Security

- Lexical and canonical path containment guard (``Crinit::PathGuard.ensure_within!``) preventing path traversal (Zip Slip) and symlink escape attacks.
- Destination symlink clobbering defense deleting target symlinks before file writes in all rendering pipelines.
- Strict SSRF mitigation in ``Crinit::AssetFetcher`` with dotted-octet IP parsing blocking private (RFC 1918), loopback (``127/8``), link-local/cloud metadata (``169.254/16``, ``metadata.google.internal``), and unique-local IPv6 (``fc00::/7``, ``fe80::/10``) ranges.
- Enforced mandatory SHA-256 checksum integrity verification for executable remote assets.
- Maximum payload streaming ceiling of 50 MiB on remote asset downloads to prevent stream bombs.
- Strict skeleton type identifier validation (allowing alphanumeric characters, hyphens, and underscores) in CLI and template resolver.

.. rubric:: Changed

- Replaced CLI argument parser to support ``--template <path> <dir>`` without requiring placeholder type tokens.
- Normalized module name derivation in ``TokenEngine.module_name`` to fold numeric segments into valid Crystal constant identifiers.
- Switched default compiler flags in GNUmakefile to portable release mode (``--release --no-debug``).
