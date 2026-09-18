============================================
ADR: Pluggable Filesystem Template Discovery
============================================


Status
------
Accepted (2026-09-18)

Context
-------
Upstream ``crystal init`` relies on compile-time embedded ECR macros (``ECR.def_to_s``). This prevents any runtime expansion or user customization without modifying and recompiling the compiler itself.

Decision
--------
Implement a dual-mode template resolution engine:

1. Preserve embedded ECR views as default fallbacks for ``app`` and ``lib``.
2. Introduce a filesystem-driven template walker that discovers templates across standard user and system directories.
3. Decouple network fetching from the generator, leaving template distribution to standard Git or package managers.

Consequences
------------

* **Positive**: Complete user freedom over directory layouts, licenses, and files. 100% backward compatible. Zero network risk for the compiler.
* **Negative**: Requires a lightweight runtime token replacement engine since runtime ECR cannot be dynamically evaluated in Crystal.
