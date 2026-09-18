========================================
ADR: Remote Assets and 4-Tier Fallback
========================================


Status
------
Accepted (2026-09-18)

Context
-------
Template authors developing production starters (such as Kemal, Datastar, and Blueprint stacks) frequently require external static assets: upstream software licenses (e.g., GPLv3 from gnu.org), governance documents (e.g., Code of Honor from gitlab.com/renich/coh), frontend vendor scripts (e.g., Datastar, HTMX, Pico CSS), or typography.

Duplicating these assets manually across multiple template repositories introduces repository bloat, version drift, and synchronization friction. However, naive on-the-fly network downloads during project scaffolding present severe engineering risks:

1. **Air-gapped/offline failure**: Project generation fails when working on airplanes, trains, or inside network-isolated CI/CD build environments.
2. **Upstream Crystal PR conflict**: The Crystal compiler repository strictly forbids network operations inside the core compiler toolchain (the rationale behind spinning out ``crystal deps`` into ``shards``).
3. **Performance degradation**: Downloading multiple HTTP assets destroys ``crinit``'s instantaneous 14 ms execution speed, introducing multi-second network latency.
4. **Supply-chain vulnerabilities**: Fetching unpinned remote URLs introduces non-deterministic builds and security tampering risks.

Decision
--------
Implement a declarative ``template.yml`` manifest specification supporting optional remote asset declarations backed by a **4-tier resolution pipeline and content-addressed SHA-256 caching**:

1. **Tier 1 (Content-Addressed Local Cache)**:
   Assets are stored by their SHA-256 digest in the standard user cache directory (``$XDG_CACHE_HOME/crystal/crinit/assets/<sha256>`` on Linux). Cache hits resolve locally in sub-millisecond time with zero network access.

2. **Tier 2 (Integrity-Pinned HTTP Fetch)**:
   When an asset is absent from cache and the ``--offline`` flag is not active, ``crinit`` downloads the asset over HTTPS with a strict 3-second connect/read timeout and automatic redirect resolution. The downloaded payload is checked against the declared ``sha256`` digest. Any checksum mismatch aborts immediately with a fatal security error to prevent supply-chain tampering. Valid downloads are committed to the local cache.

3. **Tier 3 (Bundled Template Fallback)**:
   If network access is unavailable, times out, fails with an HTTP error, or if ``--offline`` is specified, ``crinit`` falls back to a local bundled asset file declared in the template manifest (e.g., ``assets/vendor/datastar.js`` or ``assets/licenses/gpl-3.0.txt``).

4. **Tier 4 (Graceful Degradation)**:
   If both network retrieval and bundled fallbacks are unavailable, ``crinit`` issues a prominent warning and writes a ``.todo`` placeholder file detailing manual retrieval instructions, avoiding corrupting or aborting the remainder of the scaffolded project.

5. **Decoupled Architecture for Upstream PR**:
   The core filesystem mirrorer and token substitution engine remain 100% network-free. The remote asset resolution logic is isolated in a modular ``Crinit::AssetFetcher`` subsystem, allowing the upstream Crystal compiler PR (``crystal init``) to gate or omit network fetching without altering the core scaffolding engine.

Consequences
------------

* **Positive**: Full flexibility for rich web templates. 100% offline and air-gapped resilience. Sub-millisecond performance on cached assets. Cryptographic supply-chain integrity verification. Clean path for upstream Crystal compiler integration.
* **Negative**: Template authors must declare expected SHA-256 digests in ``template.yml`` to leverage caching and security validation.
