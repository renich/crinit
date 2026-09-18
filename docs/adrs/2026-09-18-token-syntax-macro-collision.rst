
=================================================
ADR: Token Syntax & Crystal Macro Collision Guard
=================================================

Status
------
Accepted (2026-09-18)

Context
-------
Crystal source files frequently utilize macros with delimiters matching ``{{ ... }}`` and ``{% ... %}``. If a template replaces arbitrary double curly braces, it will corrupt legitimate Crystal macros in template source files.

Decision
--------

1. Standardize on ``{{identifier}}`` token syntax, restricting keys to alphanumeric and underscore characters.
2. Bound replacement strictly to keys present in the dictionary. If an expression like ``{{ flag?(:linux) }}`` is encountered, it is left untouched.
3. Provide an escaping mechanism where ``\{{ ... \}}`` renders as literal ``{{ ... }}``.

Consequences
------------

* **Positive**: Full safety when templating complex Crystal files containing native macros.
* **Negative**: Template authors must be aware of the bounded dictionary and avoid creating variables that collide with built-in Crystal macro names.
