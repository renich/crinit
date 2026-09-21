=========
Changelog
=========

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.1.0/>`_,
and this project adheres to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`_.

[0.1.1] - 2026-09-21
====================

.. rubric:: Security

- Hardened ``Crinit::AssetFetcher`` against Server-Side Request Forgery (SSRF) and DNS rebinding by resolving hostnames via ``Socket::Addrinfo`` and validating all resolved addresses against loopback, private RFC 1918, link-local, and cloud metadata IP ranges.
- Hardened ``Crinit::PathGuard`` against intermediate directory symlink traversal by recursively inspecting existing ancestor path segments and verifying canonical filesystem realpaths.
- Hardened ``Crinit::RemoteTemplateResolver`` against Git command option injection by rejecting branch/tag refs starting with hyphens and adding the ``--`` positional argument delimiter before remote clone URLs.

.. rubric:: Added

- Remote Git repository and forge template resolution (``Crinit::RemoteTemplateResolver``) supporting direct Git URLs (``https://``, ``http://``, ``git://``, ``git@``, ``ssh://``, and ``file://``).
- Native Shards forge shorthand expansion for ``github:owner/repo`` and ``gitlab:owner/repo`` (matching official ``shard.yml`` dependency semantics).
- Branch, tag, and commit ref pinning via RFC 3986 URI fragments (``#ref``) and the ``-b``/``--branch <ref>`` CLI option.
- Repository subpath scoping via the ``--subpath <path>`` CLI option with ``PathGuard`` path traversal protection.
- Deterministic local cache pipeline under ``$XDG_CACHE_HOME/crystal/crinit/remotes/`` with shallow cloning (``--depth 1``).
- Unified cache refresh flag (``-r``/``--refresh``) to force re-fetching remote templates and remote assets.
- Full offline resilience under ``--offline`` serving cached repositories with sub-millisecond execution and fatal preflight checks for uncached templates.
- Architecture Decision Record :doc:`/adrs/2026-09-20-remote-template-repositories` (ADR-005).

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
