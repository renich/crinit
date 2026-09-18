=================
Problem Statement
=================

Context & Background
--------------------
The Crystal programming language compiler provides a built-in scaffolding command, ``crystal init``, implemented in ``src/compiler/crystal/tools/init.cr``. This command is responsible for creating initial project skeletons for new libraries (``crystal init lib <name>``) and applications (``crystal init app <name>``).

While functional for bare minimum starters, the upstream implementation has remained frozen for years and exhibits several architectural limitations that hinder production engineering.

Defects of the Upstream Scaffolder
----------------------------------

1. **Hardcoded File Inventory**:
   The compiler explicitly declares a static set of eight views: ``.gitignore``, ``.editorconfig``, ``LICENSE``, ``README.md``, ``shard.yml``, ``src/<name>.cr``, ``spec/spec_helper.cr``, and ``spec/<name>_spec.cr``. Adding any additional configuration file requires modifying compiler source code.

2. **Monolithic Flat Hierarchy**:
   Modern production architectures require domain-segregated directory structures, such as ``config/``, ``containers/``, ``packaging/``, ``scripts/``, and multi-tier Sphinx documentation suites (``docs/business/``, ``docs/functional/``, ``docs/technical/``, ``docs/adrs/``, ``docs/project/``). The current tool forces all projects into a single flat file under ``src/``.

3. **Mandatory License Lock-In**:
   The embedded ``LICENSE`` and ``shard.yml`` templates strictly mandate the MIT license. Organizations or open-source authors wishing to release software under copyleft terms (GPLv3, AGPLv3, MPL-2.0) or commercial terms are forced to manually overwrite license headers after initialization.

4. **Zero Community or Organizational Extensibility**:
   Framework authors (such as Kemal, Lucky, Athena, and Blueprint) cannot provide canonical skeletons. Instead, they must either maintain bespoke generator shards (e.g., ``lucky_cli``) or instruct developers to perform tedious manual setup.

5. **Shell Script Band-Aids**:
   To bypass these constraints, developers and organizations are forced to maintain external shell scripts (such as the Bash-based ``scripts/init-project.bash`` in the ``init/`` project). While effective locally, Bash scripts fail cross-platform requirements on Windows and cannot be adopted as standard Crystal workflows.

Strategic Objective
-------------------
``crinit`` provides a zero-dependency, cross-platform, filesystem-driven template engine designed to replace the rigid views inside ``src/compiler/crystal/tools/init.cr``, paving the way for an upstream Crystal RFC and Pull Request.
