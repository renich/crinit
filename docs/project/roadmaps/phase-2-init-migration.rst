==================================
Phase 2: Legacy Template Migration
==================================

Timeline & Objectives
---------------------
Migrate the existing production blueprints from the ``init/`` project (Bash-based ``init-project.bash``) into first-class ``crinit`` template skeletons, proving arbitrary tree mirroring in production scenarios.

Milestones & Deliverables
-------------------------

* **Milestone 2.1: Ingest Application Blueprint (`app/`)** (Fulfills `[FUNC-003]`, `[FUNC-005]`, `[FUNC-006]`):

  - [ ] Convert ``init/app/`` into a native ``crinit`` template directory.
  - [ ] Replace Bash `sed` tokens with standard ``{{name}}``, ``{{module_name}}``, ``{{author}}``, ``{{email}}``.
  - [ ] Retain Sphinx documentation suite (``docs/``), Podman Quadlets (``containers/``), and RPM spec (``packaging/``).
  - [ ] Validate SVG banner and icon asset passthrough without corruption.

* **Milestone 2.2: Ingest Library Blueprint (`lib/`)** (Fulfills `[FUNC-003]`, `[FUNC-004]`):

  - [ ] Convert ``init/lib/`` into a native ``crinit`` template directory.
  - [ ] Configure GPLv3 / GNU FDL copyleft license headers.
  - [ ] Retain Ameba and Flaw configuration and example runners.

* **Milestone 2.3: End-to-End Scaffolding Verification**:

  - [ ] Scaffold sample application using ``crinit --template ... sample_app``.
  - [ ] Verify ``make check`` passes cleanly inside newly scaffolded projects.
  - [ ] Verify ``crstlint -r .`` passes inside scaffolded Sphinx docs.

Dependency Graph & Critical Path
--------------------------------

- **Critical Path**: Phase 1 MVP completion $\to$ Ingest ``app/`` $\to$ Ingest ``lib/`` $\to$ E2E validation.
- **Blocked By**: Phase 1 (Core prototype engine).
- **Unblocks**: Phase 3 (Upstream RFC submission).
