================
Coding Standards
================

Requirement Mapping
-------------------
Fulfills `[TECH-001]`, `[TECH-006]`.

Core Precepts
-------------

1. **Zero External Shard Dependencies**:
   All core functionality must reside in the Crystal standard library (``OptionParser``, ``YAML``, ``File``, ``Dir``, ``Process``, ``Path``). This ensures immediate readiness for merging into ``src/compiler/crystal/tools/init.cr``.

2. **Static Analysis & Linting**:

   - Zero Ameba warnings permitted.
   - Zero Flaw security issues permitted.
   - Maximum line length is strictly 132 characters.

3. **Error Handling & Safety**:

   - No unsafe ``.not_nil!`` assertions. Explicit ``if/case`` guards or nilable handling.
   - User errors must raise structured ``Crinit::Error`` subclasses and print clean, actionable messages to ``STDERR``.

4. **Resource Management**:

   - Files and directory streams must be closed promptly via block forms (``File.open { ... }``).
   - Temporary test directories in specs must be cleaned up reliably via ``ensure`` blocks.
