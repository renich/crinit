
=============================================
ADR: Cross-Platform Path Resolution Hierarchy
=============================================

Status
------
Accepted (2026-09-18)

Context
-------
Upstream Crystal compiler features must function reliably across Linux, macOS, and Windows. A solution that only accounts for Linux XDG standards will be rejected during upstream RFC review.

Decision
--------
Implement tiered search path discovery matching established compiler conventions (such as ``CacheDir`` and ``CrystalPath``):

- Linux/BSD: ``$XDG_DATA_HOME/crystal/templates``
- macOS: ``~/Library/Application Support/crystal/templates``
- Windows: ``%LOCALAPPDATA%\crystal\templates``
- Universal local override: ``./.crystal/templates/``

Consequences
------------

* **Positive**: Full platform parity, honoring native OS conventions without requiring external shims.
* **Negative**: Multiple conditional branches in path resolution depending on compile-time platform flags.
