=====================
Architecture Overview
=====================

Requirement Traceability
------------------------

* **[TECH-001] Core Module & CLI Dispatch**: Fulfills `[FUNC-001]`.
* **[TECH-002] Multi-Platform Template Resolver**: Fulfills `[FUNC-002]`.
* **[TECH-003] Directory Tree Mirroring Engine**: Fulfills `[FUNC-003]`.
* **[TECH-004] Token Engine & Macro Collision Guard**: Fulfills `[FUNC-004]`.
* **[TECH-005] Binary Asset Detection & Permissions**: Fulfills `[FUNC-005]`, `[FUNC-006]`.
* **[TECH-006] Manifest Parser & Git Execution**: Fulfills `[FUNC-007]`, `[FUNC-008]`.

Component Decomposition
-----------------------

1. **CLI Layer (`Crinit::CLI`)**:

   - Parses arguments using standard library `OptionParser`.
   - Validates project names: must be lowercase alphanumeric, dashes, or underscores, cannot start with a digit, and cannot exceed 50 characters.
   - Extracts metadata from Git via `Crinit::Git` (`user.name`, `user.email`, `github.user`).

2. **Template Resolver (`Crinit::TemplateResolver`)**:

   - Inspects explicit CLI flag (`--template`).
   - Parses environment variable ``CRYSTAL_TEMPLATE_PATH`` using ``Process::PATH_DELIMITER``.
   - Queries OS-native platform directories using compile-time platform flags (``flag?(:windows)``, ``flag?(:darwin)``).
   - Falls back to embedded ECR views if ``TYPE`` is ``app`` or ``lib`` and no filesystem override exists.

3. **Token Engine (`Crinit::TokenEngine`)**:

   - Compiles a key-value dictionary of standard variables and custom manifest variables.
   - Performs two-pass string replacement:

     - Pass 1: Unescapes explicit literal markers (``\{{`` $\to$ ``{{``).
     - Pass 2: Replaces strictly recognized dictionary keys (``{{key}}`` $\to$ ``value``).

   - Leaves unmapped ``{{ ... }}`` blocks untouched, preserving Crystal macro calls.

4. **Tree Mirrorer (`Crinit::TreeMirrorer`)**:

   - Recursively walks template directories using ``Dir.glob`` or recursive directory iteration.
   - Interpolates directory paths and filenames before creation.
   - Skips ``template.yml`` and ``.git`` directories in the template root.
   - Preserves POSIX file modes (``File.info(path).permissions``) on Linux and macOS.
