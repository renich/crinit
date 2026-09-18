
=============================
Phase 3: Upstream Crystal RFC
=============================

Timeline & Objectives
---------------------
Draft, submit, and shepherd the formal Crystal RFC in ``crystal-lang/rfcs``, engaging the core maintainers and community to reach consensus on the pluggable template architecture.

Milestones & Deliverables
-------------------------

* **Milestone 3.1: Author Formal RFC Document**:

  - [ ] Draft RFC following official ``crystal-lang/rfcs`` format.
  - [ ] Include detailed motivation, cross-platform path resolution matrix, backward compatibility guarantees, and macro safety proofs.
  - [ ] Incorporate dogfooding data and real-world results from Phase 1 and Phase 2.

* **Milestone 3.2: Community & Core Team Review**:

  - [ ] Open RFC Pull Request on GitHub (``crystal-lang/rfcs``).
  - [ ] Present design in Crystal forum / discussion channels.
  - [ ] Address feedback regarding Windows support, path delimiters, and token delimiters.

* **Milestone 3.3: Final Comment Period (FCP) & Approval**:

  - [ ] Incorporate core team revisions into the RFC.
  - [ ] Achieve RFC approval and merge into ``crystal-lang/rfcs``.

Dependency Graph & Critical Path
--------------------------------

- **Critical Path**: Phase 2 verification $\to$ RFC authoring $\to$ RFC submission $\to$ FCP approval.
- **Blocked By**: Phase 2 (Real-world template proof of concept).
- **Unblocks**: Phase 4 (Compiler Pull Request).
