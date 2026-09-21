=============
User Personas
=============

Primary Stakeholders
--------------------

Gus the Infrastructure Engineer & SRE Lead
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Role**: Principal Systems Architect and DevOps Lead.
* **Context**: Deploys rootless Podman containers, manages Fedora/RHEL hosts, automates GitLab CI/CD, and enforces strict SELinux policies.
* **Pain Point**: Current ``crystal init`` gives no container files, no Quadlet definitions, and no RPM spec skeletons. He has to copy them from previous repositories or run custom Bash scripts.
* **Needs**: Ability to define a personal/corporate ``service`` template containing ``containers/``, ``GNUmakefile``, and ``.gitlab-ci.yml``, initialized with a single command on any machine.

Sarah the FOSS Shard Author
~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Role**: Independent open-source library maintainer.
* **Context**: Writes reusable algorithms and database drivers for the Crystal shard ecosystem.
* **Pain Point**: Forced to delete and rewrite ``LICENSE`` and ``shard.yml`` because her projects use copyleft licenses (GPLv3) rather than MIT.
* **Needs**: Skeletons that respect author choice of licensing, include pre-configured Ameba linting, and support multi-tier documentation.

Marcus the Web Framework Maintainer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Role**: Lead developer of a hypermedia web framework (e.g., Kemal, Athena, Datastar).
* **Context**: Wants developers to experience a frictionless "hello world" that demonstrates modern web patterns.
* **Pain Point**: Cannot integrate his framework into ``crystal init``. Directs users to clone starter repos, which quickly bitrot.
* **Needs**: Official, pluggable template directories where users can run ``crystal init my-framework my_app`` or point directly to framework repository starters.

Xen the Community Developer & Starter Author
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Role**: Crystal community developer sharing specialized starter setups on GitHub/GitLab.
* **Context**: Maintains community templates for niche architectures, microservices, and game dev.
* **Pain Point**: Users find it clumsy to copy template repositories into local XDG directories before scaffolding.
* **Needs**: Ability to share a single command: ``crinit https://github.com/kemalcr/kemal my_app`` or ``crinit github:user/starter my_app``.

Elena the Crystal Compiler Core Maintainer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Role**: Core team reviewer evaluating language RFCs and Pull Requests.
* **Context**: Guards the compiler repository against bloat, network liabilities, external dependencies, and platform-specific regressions.
* **Pain Point**: Rejects proposals that introduce network dependencies, runtime interpreters, or third-party shards into the compiler binary.
* **Needs**: A zero-dependency, offline-first, backward-compatible PR that works identically on Linux, macOS, and Windows.
