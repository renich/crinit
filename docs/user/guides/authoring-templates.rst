===================
Authoring Templates
===================

Template Directory Anatomy
--------------------------
A ``crinit`` template is simply a directory placed in one of the discovered template search paths:

.. code-block:: text

   ~/.local/share/crystal/templates/microservice/
   ├── template.yml                  (Optional manifest)
   ├── .editorconfig
   ├── .gitlab-ci.yml
   ├── GNUmakefile
   ├── LICENSE
   ├── shard.yml
   ├── config/
   │   └── database/
   │       └── connection.cr
   ├── src/
   │   ├── {{name}}.cr
   │   └── {{name}}/
   │       ├── init.cr
   │       └── cli.cr
   └── spec/
       ├── spec_helper.cr
       └── {{name}}_spec.cr

Available Substitution Tokens
-----------------------------

* ``{{name}}``: Normalized project name.
* ``{{module_name}}``: PascalCase Crystal module identifier (e.g. ``my_service`` $\to$ ``MyService``).
* ``{{author}}``: Git author name.
* ``{{email}}``: Git author email.
* ``{{github_user}}``: GitHub/GitLab account name.
* ``{{year}}``: Current calendar year.
* ``{{crystal_version}}``: Current Crystal compiler version.

Crystal Macro Escaping
----------------------
If your template contains Crystal macro expressions that should not be evaluated during scaffolding, escape them with backslashes:

.. code-block:: text

   \{{ flag?(:linux) \}}

The engine will unescape them during rendering to output literal Crystal macro syntax:

.. code-block:: text

   {{ flag?(:linux) }}

Template Manifest and Remote Assets
-----------------------------------
Templates can optionally include a ``template.yml`` manifest in the template root directory to declare metadata and external remote assets:

.. code-block:: yaml

   name: "kemal-pro"
   description: "Production Kemal web application with Datastar and Pico CSS"
   author: "Rénich Bon Ćirić"

   remote_assets:
     - target: "LICENSE"
       url: "https://www.gnu.org/licenses/gpl-3.0.txt"
       sha256: "3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986"
       fallback: "assets/licenses/gpl-3.0.txt"

     - target: "public/js/datastar.js"
       url: "https://cdn.jsdelivr.net/gh/starfederation/datastar@v1.0.0-beta.9/bundles/datastar.js"
       sha256: "b4c27a9223efcbeae664db88647ba3b6ea278d6b6bf091feaa3c74c3e7f4740e"
       fallback: "assets/vendor/datastar.js"

4-Tier Smart Fallback Resolution
--------------------------------
When remote assets are declared, ``crinit`` processes them using a 4-tier resolution hierarchy:

1. **Tier 1 (Local Cache Hit)**: Assets verified by SHA-256 are retrieved from ``$XDG_CACHE_HOME/crystal/crinit/assets/<sha256>`` in sub-millisecond time with zero network activity.
2. **Tier 2 (Integrity-Pinned Fetch)**: If not in cache and ``--offline`` is not set, the asset is downloaded with a 3-second timeout and validated against the declared SHA-256 checksum. Hash mismatches trigger a fatal security error.
3. **Tier 3 (Bundled Fallback)**: If network access times out, is unreachable, or ``--offline`` is specified, ``crinit`` falls back to the bundled file inside the template directory.
4. **Tier 4 (Graceful Stub)**: If neither remote fetch nor bundled fallback succeeds, a ``.todo`` placeholder is generated with manual download instructions.

CLI Controls:

* ``--offline``: Enforce local-only execution, disabling all network attempts and relying exclusively on local cache or bundled fallbacks.
* ``--refresh-assets``: Bypass the local SHA-256 cache to re-validate and download the latest asset from the remote URL.

