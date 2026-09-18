=================
Core Requirements
=================

Functional Requirements Matrix
------------------------------

* **[FUNC-001] CLI Invocation & Backward Compatibility**:
  The CLI must support the standard Crystal syntax:

  .. code-block:: text

     crinit TYPE (DIR | NAME DIR) [OPTIONS]

  Where ``TYPE`` matches any registered or discovered template identifier. The system must accept ``--force`` (overwrite), ``--skip-existing`` (preserve existing files), ``--template <path>`` (explicit path), and ``--help``. Invoking ``crinit app <name>`` or ``crinit lib <name>`` must produce identical output to ``crystal init`` if no overriding filesystem template exists.

* **[FUNC-002] Multi-Platform Template Discovery**:
  The system must resolve template directories deterministically across platforms using the following priority order:

  1. Explicit CLI argument (``--template <path>``).
  2. Environment variable ``CRYSTAL_TEMPLATE_PATH`` (split by ``Process::PATH_DELIMITER``).
  3. Workspace local directory (``./.crystal/templates/<TYPE>``).
  4. User template directory (Linux: ``$XDG_DATA_HOME/crystal/templates/<TYPE>``; macOS: ``~/Library/Application Support/crystal/templates/<TYPE>``; Windows: ``%LOCALAPPDATA%\crystal\templates\<TYPE>``).
  5. System template directory (Linux: ``/usr/share/crystal/templates/<TYPE>``; macOS: ``/opt/homebrew/share/crystal/templates/<TYPE>``; Windows: ``%ProgramFiles%\Crystal\templates\<TYPE>``).
  6. Built-in embedded fallbacks (``app``, ``lib``).

* **[FUNC-003] Recursive Directory Tree Mirroring**:
  The engine must traverse the selected template folder recursively and replicate all subdirectories and files into the destination directory without flattening or dropping paths.

* **[FUNC-004] Macro-Safe Token Replacement**:
  The engine must evaluate standard substitution tokens in both file contents and file/directory paths:

  - ``{{name}}``: Normalized project name.
  - ``{{module_name}}``: PascalCase Crystal module identifier (e.g., ``telemetry_daemon`` $\to$ ``TelemetryDaemon``, ``foo-bar`` $\to$ ``Foo::Bar``).
  - ``{{author}}``: Author name from ``git config user.name`` (fallback: ``your-name-here``).
  - ``{{email}}``: Author email from ``git config user.email`` (fallback: ``your-email-here``).
  - ``{{github_user}}``: GitHub username from ``git config github.user`` (fallback: ``your-github-user``).
  - ``{{year}}``: Current calendar year (``Time.local.year``).
  - ``{{crystal_version}}``: Active compiler version (``Crystal::Config.version``).

  Unrecognized ``{{ ... }}`` patterns must be ignored to prevent syntax collisions with Crystal's native macro expressions. Escaped tokens (``\{{ ... \}}``) must unescape to literal ``{{ ... }}``.

* **[FUNC-005] Binary Asset & Media Passthrough**:
  The engine must distinguish text files from binary assets (e.g., PNG, JPEG, SVG, compiled binaries). Binary files must be copied byte-for-byte without UTF-8 string encoding or token inspection.

* **[FUNC-006] POSIX Permission Preservation**:
  On POSIX-compliant systems (Linux and macOS), executable permission bits (``0o755``) on template scripts and hooks must be preserved when rendered into the target repository.

* **[FUNC-007] Optional Template Manifest**:
  Templates may include an optional ``template.yml`` (or ``template.yaml``) manifest defining metadata, variable definitions with defaults, and mixin conditions. The manifest file itself must be excluded from the generated project output.

* **[FUNC-008] Automated Git Repository Initialization**:
  Unless explicitly disabled via ``--no-git`` or manifest configuration, the engine must initialize a Git repository in the destination directory and configure default branches.
