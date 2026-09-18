=========================
Contributing to crinit
=========================

Thank you for your interest in contributing to ``crinit``. We welcome contributions from human engineers and autonomous agents who share our commitment to software excellence, security rigor, and empirical verification.

Code of Honor
=============

All contributors are expected to uphold the principles defined in `CODE_OF_HONOR.rst <CODE_OF_HONOR.rst>`_. We build resilient, well-tested software, demand intellectual honesty, operate transparently, and verify all system properties empirically.

Development Workflow
====================

Prerequisites
-------------

* `Crystal <https://crystal-lang.org/>`_ (>= 1.21.0)
* `GNU Make <https://www.gnu.org/software/make/>`_
* `Git <https://git-scm.com/>`_

Getting Started
---------------

1. Fork the repository on `GitLab <https://gitlab.com/renich/crinit>`_ or `GitHub <https://github.com/renich/crinit>`_.
2. Clone your fork locally:

   .. code-block:: bash

      git clone https://gitlab.com/renich/crinit.git
      cd crinit

3. Run the test suite:

   .. code-block:: bash

      make spec

4. Run the full verification quality gates:

   .. code-block:: bash

      make check

Coding Standards
================

* **Zero External Runtime Dependencies**: All runtime functionality must use Crystal standard library exclusively.
* **Strict Static Analysis**: All code must pass Ameba (zero warnings) and Flaw (zero findings).
* **Documentation**: All documentation is written in reStructuredText and validated with ``crstlint``.
* **Commits**: Follow Conventional Commits format (``type(scope): description``) with signed commits (``git commit -s``).
