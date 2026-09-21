===================================================
ADR: Remote Template Repositories and Cache Manager
===================================================


Status
------
Accepted (2026-09-20)

Context
-------
Following community feedback on the Crystal RFC forum (topic 9156), template authors and users requested direct initialization from remote Git repositories (e.g., ``crinit https://github.com/kemalcr/kemal-starter my_app``).

Currently, ``crinit`` strictly resolves templates from the local filesystem, workspace overrides, XDG user/system directories, and built-in views. Template parameters are restricted to alphanumeric identifiers, requiring users to manually clone external starter repositories, strip Git history, and manually invoke substitution tools.

However, remote template resolution introduces distinct operational constraints:

#. **Upstream compiler isolation**: The core Crystal compiler strictly limits network dependencies. Remote fetching must be modular and decoupled from core tree mirroring.
#. **Offline and air-gapped resilience**: Developers working offline or in air-gapped CI/CD environments must be able to use previously fetched templates without network failures.
#. **Security and supply-chain safety**: Fetching arbitrary remote repositories must prevent argument/shell injection, directory traversal via repository subpaths, and unwanted execution of arbitrary scripts.

Decision
--------
Implement remote template repository support in ``crinit`` backed by a dedicated ``Crinit::RemoteTemplateResolver``, shallow Git cloning, and content-addressed local caching:

#. **Universal Git URIs & Shards Shorthands**:
   Support standard Git URLs (``https://``, ``http://``, ``git://``, ``git@``, ``ssh://``) alongside standard Crystal Shards forge shorthands:

   * ``github:org/repo`` $\to$ ``https://github.com/org/repo.git``
   * ``gitlab:org/repo`` $\to$ ``https://gitlab.com/org/repo.git``

#. **Deterministic Branch & Ref Pinning**:
   Support ref/branch/tag specification via standard RFC 3986 URI fragments (e.g., ``https://github.com/kemalcr/kemal#v1.2.0`` or ``github:kemalcr/kemal#main``) as well as the ``--branch <ref>`` CLI option.

#. **Unix-Standard Subpath Scoping**:
   Support repository subdirectories via the standard Unix ``--subpath <path>`` option (e.g., ``crinit github:kemalcr/starters my_app --subpath starters/web``). The subpath is verified against path traversal using ``PathGuard.ensure_within!``.

#. **Content-Addressed Local Cache Pipeline**:
   Remote repositories are cached in ``$XDG_CACHE_HOME/crystal/crinit/remotes/<repo_slug>_<sha256_of_uri>/``:

   * **Cache Hit**: If cached, the engine resolves the template from local disk in sub-millisecond time.
   * **Online Fetch**: If absent from cache, ``crinit`` executes ``git clone --depth 1 [--branch <ref>] <url> <cache_path>`` directly via ``Process.run`` (avoiding shell execution).
   * **Offline Mode (``--offline``)**: If cached, use cache. If absent, abort immediately with fatal ``TemplateNotFoundError`` without network latency.
   * **Cache Refresh (``--refresh``)**: Unified ``--refresh`` flag forces re-fetching/updating remote repositories and re-downloading remote assets.

#. **Decoupled Architecture for Compiler Upstreaming**:
   The remote resolution pipeline returns a standard ``DirectoryTemplateSource`` pointing to the cached repository (or subpath). ``TreeMirrorer`` ignores ``.git/`` entries at the root, and a fresh Git repository is initialized in the destination project.

Consequences
------------

* **Positive**: Single-command project initialization from any public or private Git repository or forge. Complete offline resilience for cached templates. Native compatibility with Shards dependency shorthand patterns. Zero third-party shard dependencies.
* **Negative**: Requires system ``git`` binary installed in ``PATH`` to fetch uncached remote repositories.
