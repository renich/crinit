============
User Stories
============

Overview
--------
This document formalizes actionable user stories and acceptance criteria for ``crinit``, grounding technical features in real-world stakeholder needs.

Stories & Acceptance Criteria
-----------------------------

US-001: Remote Git Scaffolding
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **User Story**: As Marcus (the web framework maintainer) or Xen (a community developer), I want to initialize a new Crystal project directly from a remote Git repository URL or shorthand (e.g., ``crinit https://github.com/kemalcr/kemal-starter my_app`` or ``crinit github:kemalcr/kemal-starter my_app``), so that my users can scaffold production applications without manually cloning, stripping git metadata, or editing files by hand.
* **Acceptance Criteria**:

   #. The CLI accepts valid Git repository URLs (``https://``, ``http://``, ``git://``, ``git@``, ``ssh://``) as the template parameter.
   #. The CLI accepts standard Shards-compatible forge shorthands (``github:org/repo`` and ``gitlab:org/repo``).
   #. Users can target specific tags or branches using standard RFC 3986 URI fragments (``#v1.0.0``) or via the ``--branch <ref>`` flag.
   #. Users can target subdirectories within a repository using the ``--subpath <path>`` flag.
   #. Cloned repositories are stored in the user cache directory (``$XDG_CACHE_HOME/crystal/crinit/remotes/``) using shallow clones (``--depth 1``).
   #. The remote repository's ``.git/`` folder is never copied into the target project.
   #. A fresh Git repository is initialized in the target project unless ``--no-git`` is specified.

US-002: Offline Resilience for Remote Templates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **User Story**: As Nyx or Gus (an air-gapped systems architect/SRE), I want ``crinit`` to resolve previously fetched remote templates from the local cache when ``--offline`` is passed, so that project generation never fails on offline workstations or inside air-gapped CI/CD build environments.
* **Acceptance Criteria**:

   #. If a remote template has been cached and ``--offline`` is active, the engine renders from cache with zero network access.
   #. If a remote template is not present in cache and ``--offline`` is active, execution halts immediately with a clear diagnostic error without hanging on network timeouts.
   #. When ``--refresh`` is passed online, the cached repository is updated or re-fetched.
