=================
Token Engine Spec
=================

Requirement Mapping
-------------------
Fulfills `[TECH-004]`, `[FUNC-004]`.

Design Rationale
----------------
In Crystal, macros use ``{{ ... }}`` syntax. A naive regex replacing all ``{{ .* }}`` instances will corrupt valid Crystal code in template files (e.g., ``{{ flag?(:linux) }}`` or ``\{{ @type.name \}}``).

The token engine must guarantee macro safety while supporting rich template substitution.

Token Substitution Algorithm
----------------------------

1. **Dictionary Construction**:
   The engine builds a strictly typed ``Hash(String, String)`` containing:

   * ``name``: Raw project name (e.g., ``telemetry_daemon``).
   * ``module_name``: Formatted module identifier (e.g., ``TelemetryDaemon``).
   * ``author``: Git author name.
   * ``email``: Git author email.
   * ``github_user``: GitHub or GitLab account username.
   * ``year``: Current four-digit calendar year.
   * ``crystal_version``: Current running Crystal compiler version string.

2. **Regex Pattern Matching**:
   Token scanning matches strictly formatted identifier patterns:

   .. code-block:: text

      /\{\{([a-zA-Z0-9_]+)\}\}/

3. **Substitution Evaluation**:
   For each match:

   * If the extracted key exists in the dictionary, replace ``{{key}}`` with the mapped string.
   * If the extracted key does not exist in the dictionary, **leave the match untouched**.

4. **Escaping Protocol**:
   To emit a literal ``{{name}}`` in generated output:

   * Author writes: ``\{{name\}}``.
   * Engine transforms ``\{{`` into ``{{`` and ``\}}`` into ``}}``.

Path Interpolation
------------------
The same dictionary is applied to relative file and directory paths before file writing:

* Template path: ``src/{{name}}/init.cr``
* Destination path: ``src/telemetry_daemon/init.cr``
