# crinit

> **Next-Generation Pluggable Project Scaffolding for Crystal**

`crinit` is an extensible, cross-platform project scaffolding engine for the Crystal programming language.

---

## 🎯 Intent & Upstream Vision

**This project was created with the explicit intention of being proposed and merged directly into the upstream Crystal compiler (`crystal init`).**

The current implementation of `crystal init` (located in [`src/compiler/crystal/tools/init.cr`](https://github.com/crystal-lang/crystal/blob/master/src/compiler/crystal/tools/init.cr)) has been virtually unchanged since early releases. While reliable, it is architecturally rigid:

1. **Hardcoded File Set**: It can only ever generate a flat list of 8 predefined files.
2. **Hardcoded Licensing**: The MIT license is permanently baked into the binary.
3. **No Directory Hierarchy**: Complex layouts like `config/`, `db/migrations/`, or nested source namespaces (`src/<project-name>/init.cr`) are impossible without manual creation.
4. **No Custom Templates**: Framework authors (Kemal, Lucky, Athena, Blueprint) and engineering organizations cannot define or distribute their own project skeletons.

`crinit` acts as the reference prototype, testbed, and dogfooding tool to prove the design before submitting the formal [Crystal RFC](https://github.com/crystal-lang/rfcs) and Pull Request to [`crystal-lang/crystal`](https://github.com/crystal-lang/crystal).

---

## 💡 Key Architectural Principles

To ensure seamless upstream acceptance, `crinit` adheres to the strict design constraints of the Crystal compiler core:

- **Zero External Runtime Dependencies**: Uses strictly Crystal's standard library (`OptionParser`, `YAML`, `File`, `Dir`, `Process`). No heavy scripting interpreters.
- **Offline-First & Network-Decoupled**: Operates entirely on the local filesystem. Remote template fetching is intentionally decoupled to respect the compiler team's separation between `crystal` and `shards`.
- **100% Backward Compatible**: Drops in as a replacement for `crystal init app <name>` and `crystal init lib <name>`, preserving existing behavior via embedded fallbacks unless overridden.
- **Multi-Platform Native Support**: First-class support across the entire official Crystal tier matrix (Linux, macOS, Windows).
- **Arbitrary Tree Mirroring**: Complete topological freedom over directories, nested namespaces, assets, and licensing.
- **Macro-Safe Token Substitution**: Prevents syntax collisions with Crystal's native macro delimiters (`{{ ... }}`).

---

## 📂 Cross-Platform Template Resolution

`crinit` resolves templates across standard platform directories in the following order:

```
Priority 1: --template <path>                                (Explicit CLI flag)
Priority 2: CRYSTAL_TEMPLATE_PATH                           (Environment variable, split by Process::PATH_DELIMITER)
Priority 3: ./.crystal/templates/<TYPE>                     (Project/Workspace local)
Priority 4: User Data Directory                             (OS-native user path)
Priority 5: System Data Directory                           (OS-native system path or $ORIGIN-relative)
Priority 6: Built-in Defaults                               (Embedded app / lib fallback)
```

### OS Directory Mappings

| Platform | User Template Directory (`Priority 4`) | System Template Directory (`Priority 5`) |
| :--- | :--- | :--- |
| **Linux/BSD** | `$XDG_DATA_HOME/crystal/templates`<br>*(Fallback: `~/.local/share/crystal/templates`)* | `/usr/share/crystal/templates`<br>*(or `$ORIGIN/../share/crystal/templates`)* |
| **macOS** | `~/Library/Application Support/crystal/templates`<br>*(Fallback: `~/.local/share/crystal/templates`)* | `/opt/homebrew/share/crystal/templates`<br>*(or `/usr/local/share/crystal/templates`)* |
| **Windows** | `%LOCALAPPDATA%\crystal\templates`<br>*(Fallback: `%USERPROFILE%\.crystal\templates`)* | `%ProgramFiles%\Crystal\templates`<br>*(or `$ORIGIN\..\share\crystal\templates`)* |

---

## 🛠️ Template Anatomy

A custom template is simply a directory containing files, directories, and an optional manifest:

```
~/.local/share/crystal/templates/service/
├── template.yml                  # Optional metadata and variable prompts
├── .editorconfig
├── .gitlab-ci.yml
├── .ameba.yml
├── GNUmakefile
├── LICENSE                       # Use any license you want (GPLv3, Apache-2.0, etc.)
├── shard.yml
├── config/
│   └── database/
│       ├── connection.cr
│       └── migrations.cr
├── src/
│   ├── {{name}}.cr               # Entry point
│   └── {{name}}/
│       ├── init.cr               # Initialization logic
│       ├── cli.cr
│       └── app.cr
└── spec/
    ├── spec_helper.cr
    └── {{name}}_spec.cr
```

### Standard Replacement Tokens

| Token | Description | Source |
| :--- | :--- | :--- |
| `{{name}}` | Normalized project name | User argument / directory basename |
| `{{module_name}}` | CamelCase Crystal module name (e.g. `my-app` $\to$ `MyApp`) | Derived algorithm |
| `{{author}}` | Author full name | `git config user.name` |
| `{{email}}` | Author email address | `git config user.email` |
| `{{github_user}}` | GitHub/GitLab username | `git config github.user` |
| `{{year}}` | Current year | `Time.local.year` |
| `{{crystal_version}}` | Running compiler version | `Crystal::Config.version` |

Both file contents and file/directory names are dynamically expanded during scaffolding.

---

## 🚀 Usage

### Initializing Projects

```bash
# Using standard built-in skeletons (compatible with crystal init)
crinit app my_app
crinit lib my_lib

# Using a custom template installed in your user/system template path
crinit service my_microservice

# Using an explicit filesystem path
crinit --template ~/templates/kemal-blueprint my_web_app

# Forcing overwrite or skipping existing files
crinit service my_microservice --force
crinit service my_microservice --skip-existing
```

---

## 🗺️ Roadmap to Upstream Merge

1. **Phase 1: Reference Prototype (`crinit`)**
   - Implement directory tree mirroring and token substitution in pure Crystal.
   - Comprehensive cross-platform path resolution unit tests.
   - Real-world dogfooding across custom templates.
2. **Phase 2: Formal RFC**
   - Draft and submit RFC to [`crystal-lang/rfcs`](https://github.com/crystal-lang/rfcs).
   - Solicit feedback from the Crystal core team and community.
3. **Phase 3: Upstream Pull Request**
   - Refactor [`src/compiler/crystal/tools/init.cr`](https://github.com/crystal-lang/crystal/blob/master/src/compiler/crystal/tools/init.cr) in `crystal-lang/crystal`.
   - Add compiler unit specs in `spec/compiler/tools/init_spec.cr`.

---

## 👥 Authors & Maintainers

- **Rénich Bon Ćirić** ([@renich](https://gitlab.com/renich)) - Creator & Principal Architect
