# Example Templates for crinit

This directory contains reference template implementations showcasing the pluggable capabilities of `crinit`.

---

## Available Templates

### 1. `enterprise-service/`
A full-stack, production-grade Crystal microservice starter with domain-segregated layouts:
* **Architecture**: `config/database/`, `src/{{name}}/init.cr`, `src/{{name}}/cli.cr`.
* **Operations**: `containers/` (Containerfile, systemd Quadlet), `packaging/` (RPM `.spec`), `GNUmakefile`.
* **Licensing**: Demonstrates non-MIT (GPLv3) licensing.

```bash
# Test scaffold
crinit my_service ./my_service -t examples/enterprise-service
```

---

### 2. `kemal-web/`
A modern Kemal hypermedia web application inspired by the `sdogruyol/kemal-by-example` architecture:
* **Architecture**: `src/models/`, `src/routes/`, `src/views/layouts/`, `public/`.
* **Remote Assets & Fallback**: Uses `template.yml` to declare:
  - Pico CSS (`public/css/pico.min.css`)
  - Datastar (`public/js/datastar.js`)
  - Bundled offline fallbacks under `template_assets/`.
* **Offline-Resilient**: Scaffolds instantaneously from local SHA-256 cache or bundled fallbacks when offline (`--offline`).

```bash
# Online scaffold with integrity verification
crinit my_web ./my_web -t examples/kemal-web

# Air-gapped/offline scaffold
crinit my_web ./my_web -t examples/kemal-web --offline
```

---

### 3. `cli-tool/`
A streamlined CLI utility starter:
* **Features**: OptionParser integration, version module, and isolated specs.

```bash
# Test scaffold
crinit my_tool ./my_tool -t examples/cli-tool
```

---

## Installing Templates for User-Wide Access

To make any of these templates discoverable by name without passing `-t PATH`:

```bash
mkdir -p ~/.local/share/crystal/templates/
cp -r examples/enterprise-service ~/.local/share/crystal/templates/service
cp -r examples/kemal-web ~/.local/share/crystal/templates/web
cp -r examples/cli-tool ~/.local/share/crystal/templates/cli

# Now you can run:
crinit service ./my_service
crinit web ./my_web
crinit cli ./my_tool
```
