=================================
Remote Template Architecture Spec
=================================

Overview
--------
This specification defines the technical architecture of the remote template repository resolution subsystem, fulfilling ``[FUNC-009]`` and codifying :doc:`/adrs/2026-09-20-remote-template-repositories`.

Module: `Crinit::RemoteTemplateResolver`
----------------------------------------
The ``Crinit::RemoteTemplateResolver`` module isolates all network transport and remote URI normalization, providing a decoupled interface consumed by ``Crinit::TemplateResolver``.

URI Detection & Parsing
~~~~~~~~~~~~~~~~~~~~~~~
The resolver evaluates candidate strings using deterministic URI matching:

* **Direct Git Protocols**:
   Matches strings starting with ``https://``, ``http://``, ``git://``, ``git@``, or ``ssh://``.

* **Shards Forge Shorthands**:
   Matches ``github:<owner>/<repo>`` or ``gitlab:<owner>/<repo>``, expanding them to canonical HTTPS URLs:

   * ``github:org/repo`` $\to$ ``https://github.com/org/repo.git``
   * ``gitlab:org/repo`` $\to$ ``https://gitlab.com/org/repo.git``

* **Ref & Branch Extraction**:
   If a URI fragment is present (e.g., ``https://example.com/repo.git#v1.0.0``), the fragment is extracted as the target Git reference. An explicit ``--branch <ref>`` CLI option takes precedence over URI fragments.

Deterministic Cache Directory Layout
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Fetched repositories are cached in a dedicated local directory:

.. code-block:: text

   $XDG_CACHE_HOME/crystal/crinit/remotes/<repo_slug>_<sha256_hash>/

Where:

* ``repo_slug`` is sanitized to alphanumeric characters, underscores, and hyphens.
* ``sha256_hash`` is the first 16 characters of the SHA-256 digest of the canonical clone URL and ref.

Resolution Pipeline
~~~~~~~~~~~~~~~~~~~

#. **Preflight Check**:
   If ``--offline`` is enabled and the target cache directory does not exist, the resolver raises a ``TemplateNotFoundError`` immediately without invoking network operations.

#. **Cache Hit Check**:
   If the cache directory exists and contains a valid Git repository, and ``--refresh`` is false, the resolver skips the network fetch and immediately returns the cached directory.

#. **Git Transport Execution**:
   When fetching online (or when ``--refresh`` is active):

   * Verifies ``git`` executable presence via ``Crinit::Git.executable``.
   * Clones shallowly: ``git clone --depth 1 [--branch <ref>] <url> <cache_dir>``.
   * If refreshing an existing cache, runs ``git fetch --depth 1 origin <ref>`` followed by ``git reset --hard origin/<ref>`` (or re-clones cleanly).
   * Passes arguments as ``Array(String)`` to ``Process.run`` to eliminate shell injection vulnerabilities.

Subpath Scoping & Security Guard
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When the user specifies ``--subpath <path>``:

* The engine resolves ``Path.new(cache_dir, subpath)``.
* Passes the candidate through ``PathGuard.ensure_within!(cache_dir, target, "remote template subpath")``.
* If the subpath does not exist or attempts directory traversal outside the cloned repository root, a fatal error is raised.

Integration with `Crinit::TemplateResolver`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When ``Crinit::TemplateResolver.resolve(type, explicit_path, subpath)`` is called:

#. If ``explicit_path`` is provided and matches a remote URI, it is resolved via ``RemoteTemplateResolver``.
#. If ``type`` matches a remote URI, it is resolved via ``RemoteTemplateResolver``.
#. Otherwise, standard local, workspace, XDG, and system search paths are evaluated.
