======================
Business Problematics
======================

Overview
--------
This document tracks operational friction, user pain points, and edge cases identified during real-world usage and persona simulations, following the persona-driven planning protocol.

Problematics Ledger
-------------------

PROB-001: Remote Git Repository Template Scaffolding [RESOLVED]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **The Scenario**:
   A developer or framework author (e.g., Marcus or Xen) wishes to share or scaffold a Crystal project directly from a Git repository or code forge (e.g., ``crinit https://github.com/kemalcr/kemal-starter my_app`` or ``crinit github:kemalcr/kemal-starter my_app``).
* **The Pain Point**:
   ``crinit`` rejects any template parameter containing characters outside alphanumeric characters, dashes, or underscores with an ``InvalidNameError``. Users are forced to manually clone repositories, strip ``.git/`` directories, remove hardcoded author/project names using manual ``sed`` commands, and initialize a new git repository by hand.
* **Root Cause**:
   ``TemplateResolver`` only evaluates local filesystem paths, user/system XDG directories, and embedded views. ``CLI.validate_skeleton_type`` rejects URIs, and no remote Git transport or cache subsystem exists for templates.
* **Discussion Notes**:
   Discussed URI formats, Shards compatibility, subpath handling, and offline caching with Rénich. Agreed on supporting universal Git URLs, Shards-native ``github:`` and ``gitlab:`` shorthands, standard Unix ``--subpath`` and ``--branch`` flags, and a unified ``--refresh`` flag.
* **Resolution**:
   Codified and accepted in :doc:`/adrs/2026-09-20-remote-template-repositories`.
