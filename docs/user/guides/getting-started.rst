===============
Getting Started
===============

Installation
------------
Compile ``crinit`` using the standard Crystal build tool:

.. code-block:: bash

   cd ~/Projects/crystal/crinit
   shards build --release
   sudo cp bin/crinit /usr/local/bin/

Basic Project Initialization
----------------------------
``crinit`` behaves as a 100% compatible drop-in replacement for ``crystal init``:

.. code-block:: bash

   # Scaffolding a default application
   crinit app my_application

   # Scaffolding a default shard library
   crinit lib my_library

Using Custom Templates
----------------------
To scaffold from a custom template located in your user template directory:

.. code-block:: bash

   # Resolves ~/.local/share/crystal/templates/service
   crinit service telemetry_agent

   # Scaffolding directly from an explicit path
   crinit --template ~/Projects/crystal/init/app telemetry_agent

Overwriting or Skipping Files
-----------------------------

* **Force overwrite existing files**:

  .. code-block:: bash

     crinit service telemetry_agent --force

* **Skip existing files and generate missing files**:

  .. code-block:: bash

     crinit service telemetry_agent --skip-existing

Using Remote Git Templates
--------------------------
Scaffold directly from external Git repositories or code forges:

.. code-block:: bash

   # Scaffolding directly from an HTTPS Git repository
   crinit https://github.com/kemalcr/kemal-starter.git my_web_app

   # Using Shards-compatible forge shorthands
   crinit github:kemalcr/kemal-starter my_web_app

   # Pinning a specific branch or release tag
   crinit github:kemalcr/kemal-starter#v1.2.0 my_web_app
   crinit github:kemalcr/kemal-starter my_web_app --branch v1.2.0

   # Scaffolding from a subfolder within a monorepo
   crinit github:kemalcr/templates my_web_app --subpath starters/web

   # Re-fetching latest updates or running offline
   crinit github:kemalcr/kemal-starter my_web_app --refresh
   crinit github:kemalcr/kemal-starter my_web_app --offline
