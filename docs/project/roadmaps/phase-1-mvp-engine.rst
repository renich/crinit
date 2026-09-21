
=========================
Phase 1: Prototype Engine
=========================

Timeline & Objectives
---------------------
Deliver the core reference prototype of ``crinit`` in pure Crystal standard library, verifying tree mirroring, macro safety, cross-platform path resolution, and CLI mechanics.

Milestones & Deliverables
-------------------------

* **Milestone 1.1: Core Scaffolding Engine** (Fulfills `[FUNC-003]`, `[FUNC-004]`, `[TECH-003]`, `[TECH-004]`):

  - [ ] Implement ``Crinit::TokenEngine`` with macro collision avoidance and unit specs.
  - [ ] Implement ``Crinit::TreeMirrorer`` with recursive file and directory copying.
  - [ ] Implement binary file detection to bypass UTF-8 token scanning on assets.
  - [ ] Implement POSIX file permission restoration (``0o755``) for scripts.

* **Milestone 1.2: Template Discovery & CLI Interface** (Fulfills `[FUNC-001]`, `[FUNC-002]`, `[TECH-001]`, `[TECH-002]`):

  - [ ] Implement ``Crinit::TemplateResolver`` across Linux, macOS, and Windows.
  - [ ] Implement ``Crinit::CLI`` supporting standard flags (``--template``, ``--force``, ``--skip-existing``).
  - [ ] Integrate Git author/email discovery via ``Crinit::Git``.
  - [ ] Add fallback to built-in default views for ``app`` and ``lib``.

* **Milestone 1.3: Quality Gates & Verification** (Fulfills `[TECH-006]`):

  - [ ] Achieve 100% passing test coverage in ``spec/``.
  - [ ] Verify zero Ameba and Flaw warnings.
  - [ ] Validate all documentation with ``crstlint``.

* **Milestone 1.4: Remote Template Repositories** (Fulfills `[FUNC-009]`):

  - [ ] Implement ``Crinit::RemoteTemplateResolver`` with Git URL and Shards forge support.
  - [ ] Implement local cache manager under ``$XDG_CACHE_HOME/crystal/crinit/remotes/``.
  - [ ] Implement branch/tag pinning via URI fragments and ``--branch <ref>``.
  - [ ] Implement safe subpath scoping via ``--subpath <path>``.
  - [ ] Support ``--offline`` and unified ``--refresh`` cache updating.

Dependency Graph & Critical Path
--------------------------------

- **Critical Path**: TokenEngine $\to$ TreeMirrorer $\to$ TemplateResolver $\to$ CLI $\to$ Quality Gates.
- **Blocked By**: None.
- **Unblocks**: Phase 2 (Migration of ``init/`` blueprints).
