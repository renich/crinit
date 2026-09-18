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
