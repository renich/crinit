===============
Platform Matrix
===============

Requirement Mapping
-------------------
Fulfills `[TECH-002]`, `[TECH-005]`, `[FUNC-002]`, `[FUNC-006]`.

Cross-Platform Resolution Strategy
----------------------------------
To achieve acceptance in the upstream Crystal compiler, ``crinit`` must execute natively across Linux, macOS, and Windows without platform regressions.

Search Path Matrix
------------------

.. list-table::
   :widths: 20 40 40
   :header-rows: 1

   * - Platform
     - User Directory
     - System/Distribution Directory
   * - **Linux/BSD**
     - ``$XDG_DATA_HOME/crystal/templates`` (fallback: ``~/.local/share/crystal/templates``)
     - ``/usr/share/crystal/templates`` (or ``$ORIGIN/../share/crystal/templates``)
   * - **macOS**
     - ``~/Library/Application Support/crystal/templates`` (fallback: ``~/.local/share/crystal/templates``)
     - ``/opt/homebrew/share/crystal/templates`` (or ``/usr/local/share/crystal/templates``)
   * - **Windows**
     - ``%LOCALAPPDATA%\crystal\templates`` (fallback: ``%USERPROFILE%\.crystal\templates``)
     - ``%ProgramFiles%\Crystal\templates`` (or ``$ORIGIN\..\share\crystal\templates``)

Filesystem Conventions
----------------------

1. **Path Delimiters**:
   Environment variable splitting must utilize ``Process::PATH_DELIMITER`` (colon ``:`` on POSIX, semicolon ``;`` on Windows).

2. **NTFS Prohibited Characters**:
   Windows prohibits ``< > : " / \ | ? *`` in filenames. Template tokens must strictly adhere to ``{{key}}`` or ``__key__``, which are fully valid across NTFS, APFS, and ext4/Btrfs.

3. **Line Endings**:
   File writing must preserve Unix line endings (``\n``/LF) in generated source code, consistent with standard Crystal compiler conventions.

4. **File Permissions**:
   POSIX executable bits (``0o755``) are restored on Linux and macOS using ``File.chmod``. On Windows, permission modifications are gracefully bypassed via ``{% unless flag?(:windows) %}``.
