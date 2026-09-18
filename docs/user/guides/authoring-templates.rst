===================
Authoring Templates
===================

Template Directory Anatomy
--------------------------
A ``crinit`` template is simply a directory placed in one of the discovered template search paths:

.. code-block:: text

   ~/.local/share/crystal/templates/microservice/
   ├── template.yml                  (Optional manifest)
   ├── .editorconfig
   ├── .gitlab-ci.yml
   ├── GNUmakefile
   ├── LICENSE
   ├── shard.yml
   ├── config/
   │   └── database/
   │       └── connection.cr
   ├── src/
   │   ├── {{name}}.cr
   │   └── {{name}}/
   │       ├── init.cr
   │       └── cli.cr
   └── spec/
       ├── spec_helper.cr
       └── {{name}}_spec.cr

Available Substitution Tokens
-----------------------------

* ``{{name}}``: Normalized project name.
* ``{{module_name}}``: PascalCase Crystal module identifier (e.g. ``my_service`` $\to$ ``MyService``).
* ``{{author}}``: Git author name.
* ``{{email}}``: Git author email.
* ``{{github_user}}``: GitHub/GitLab account name.
* ``{{year}}``: Current calendar year.
* ``{{crystal_version}}``: Current Crystal compiler version.

Crystal Macro Escaping
----------------------
If your template contains Crystal macro expressions that should not be evaluated during scaffolding, escape them with backslashes:

.. code-block:: text

   \{{ flag?(:linux) \}}

The engine will unescape them during rendering to output literal Crystal macro syntax:

.. code-block:: text

   {{ flag?(:linux) }}
