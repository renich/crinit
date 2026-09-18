================================
Phase 4: Upstream Compiler PR
================================

Timeline & Objectives
---------------------
Port the proven ``crinit`` engine directly into the Crystal compiler repository (``crystal-lang/crystal``), refactoring ``src/compiler/crystal/tools/init.cr`` and securing upstream merge.

Milestones & Deliverables
-------------------------

* **Milestone 4.1: Compiler Core Refactor**:

  - [ ] Fork ``crystal-lang/crystal`` and create feature branch.
  - [ ] Refactor ``src/compiler/crystal/tools/init.cr`` into modular components (preserving embedded views, adding directory templates).
  - [ ] Add cross-platform path resolution methods.

* **Milestone 4.2: Comprehensive Compiler Specs**:

  - [ ] Implement compiler unit specs in ``spec/compiler/tools/init_spec.cr``.
  - [ ] Test cross-platform path resolution, token replacement, and file conflict modes.
  - [ ] Verify existing tests for ``crystal init app`` and ``crystal init lib`` pass unchanged.

* **Milestone 4.3: Upstream Pull Request & Merge**:

  - [ ] Submit PR referencing approved RFC.
  - [ ] Pass full CI across Linux, macOS, and Windows runners.
  - [ ] Merge into Crystal ``master`` for inclusion in the subsequent compiler release.

Dependency Graph & Critical Path
--------------------------------

- **Critical Path**: Phase 3 RFC approval $\to$ Compiler PR implementation $\to$ CI pass $\to$ Merge.
- **Blocked By**: Phase 3 (Approved RFC).
- **Unblocks**: Complete ecosystem availability in standard Crystal toolchain.
