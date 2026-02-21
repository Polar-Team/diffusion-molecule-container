# Agent Workflow: Dockerfile Dependency Update & Validation

## Purpose
This document provides a step-by-step workflow for an AI agent to check, update, test, and push Dockerfile dependency updates for the `diffusion-molecule-container` project.

---

## Context

The Dockerfile uses three top-level ARGs that control all versioned dependencies:

```dockerfile
ARG DIND_VERSION="<docker-dind-alpine-tag>"
ARG PYTHON_VERSIONS="<space-separated list: primary secondary tertiary>"
ARG UV_VERSION="<uv-version>"
```

All version pins are in `Dockerfile` lines 1–3. No other files need version changes for these dependencies (pyproject.toml uses semver ranges, not pins).

---

## Step 1 — Check Current Versions

Read the current ARG values from the Dockerfile:

```bash
head -5 Dockerfile
```

Note the three values:
- `DIND_VERSION`
- `PYTHON_VERSIONS` (space-separated, first = primary/global Python)
- `UV_VERSION`

---

## Step 2 — Research Latest Versions

Check each upstream source for the latest stable release:

### Docker DinD
- Source: https://hub.docker.com/_/docker/tags
- Filter tags matching pattern: `<version>-dind-alpine3.23`
- Target: highest `<major>.<minor>.<patch>-dind-alpine3.23` tag

### Python
- Source: https://www.python.org/downloads/
- Check latest patch for each minor version in use (3.13.x, 3.12.x, 3.11.x)
- Note: 3.11 and 3.12 are in "security fixes only" mode — still worth updating patches
- Do NOT upgrade minor versions (e.g. 3.11 → 3.12) without explicit instruction

### uv
- Source: https://github.com/astral-sh/uv/releases
- Prefer latest patch within the current minor series (e.g. 0.9.x) for safety
- Before jumping to a new minor (e.g. 0.9 → 0.10), review the release notes for breaking changes
- Key risk area: `uv venv` behavior changes, index configuration changes

---

## Step 3 — Update the Dockerfile

Edit only lines 1–3 of `Dockerfile`. Example:

```dockerfile
ARG DIND_VERSION="29.2.1-dind-alpine3.23"
ARG PYTHON_VERSIONS="3.13.12 3.12.10 3.11.12"
ARG UV_VERSION="0.9.30"
```

Rules:
- `PYTHON_VERSIONS` order: primary (latest 3.13.x) first, then 3.12.x, then 3.11.x
- Do not touch any other lines unless a package version in `RUN apk add` is no longer available in Alpine 3.23

---

## Step 4 — Check & Update Alpine Package Versions

The Dockerfile pins exact Alpine package versions in two `RUN apk add` blocks. These must be verified against the actual Alpine 3.23 package index on every update run.

Lookup URL pattern per package:
```
https://pkgs.alpinelinux.org/package/v3.23/main/x86_64/<package-name>
```

### Current pinned versions (verified against Alpine 3.23 on 2026-02-21)

Builder stage (`RUN apk add --no-cache --update`):

| Package | Pinned version |
|---------|---------------|
| `libffi-dev` | `3.5.2-r0` |
| `git` | `2.52.0-r0` |
| `curl` | `8.17.0-r1` |
| `bash` | `5.3.3-r1` |
| `gcc` | `15.2.0-r2` |
| `musl-dev` | `1.2.5-r21` |
| `make` | `4.4.1-r3` |
| `openssl-dev` | `3.5.5-r0` |
| `bzip2-dev` | `1.0.8-r6` |
| `zlib-dev` | `1.3.1-r2` |
| `readline-dev` | `8.3.1-r0` |
| `sqlite-dev` | `3.51.2-r0` |
| `xz-dev` | `5.8.2-r0` |
| `tk-dev` | `8.6.17-r0` |
| `patch` | `2.8-r0` |

Final stage (`RUN apk add --no-cache --update`):

| Package | Pinned version |
|---------|---------------|
| `git` | `2.52.0-r0` |
| `bash` | `5.3.3-r1` |
| `musl` | `1.2.5-r21` |
| `libffi` | `3.5.2-r0` |
| `openssl` | `3.5.5-r0` |
| `bzip2` | `1.0.8-r6` |
| `zlib` | `1.3.1-r2` |
| `readline` | `8.3.1-r0` |
| `xz` | `5.8.2-r0` |
| `tk` | `8.6.17-r0` |

For each package, fetch the lookup URL above and compare the `Version` field to the pinned value in the Dockerfile. Update any that differ.

> Note: if Alpine base version changes (e.g. `alpine3.23` → `alpine3.24`), all package versions must be re-verified since the branch changes too.

---

## Step 5 — Build the Image Locally

Run a local build to catch any issues before pushing:

```bash
docker build --no-cache -t diffusion-molecule-container:test .
```

Expected: build completes without errors.

If the build fails:
- Alpine package version mismatch → update the pinned version in the relevant `apk add` line
- Python version not found by pyenv → verify the version exists at https://www.python.org/downloads/
- uv binary URL 404 → verify the release exists at https://github.com/astral-sh/uv/releases

---

## Step 6 — Smoke Test the Built Image

Run basic validation inside the built image:

```bash
# Verify Python versions installed
docker run --rm diffusion-molecule-container:test bash -c "pyenv versions"

# Verify primary Python version
docker run --rm diffusion-molecule-container:test bash -c "python --version"

# Verify uv is available
docker run --rm diffusion-molecule-container:test bash -c "uv --version"

# Verify molecule is available
docker run --rm diffusion-molecule-container:test bash -c "molecule --version"

# Verify ansible is available
docker run --rm diffusion-molecule-container:test bash -c "ansible --version"
```

All commands should return version strings without errors.

---

## Step 7 — Run the Test Suite (if available)

```bash
cd tests/
# Check for any test scripts
ls -la
```

If test scripts exist, run them against the built image before proceeding.

---

## Step 8 — Commit and Push

Once the build and smoke tests pass:

```bash
git add Dockerfile
git commit -m "chore: update Dockerfile dependencies

- Docker DinD: <old> -> <new>
- Python: <old versions> -> <new versions>
- uv: <old> -> <new>"

git push origin main
```

Use conventional commit format. Replace `<old>` / `<new>` with actual version strings.

---

## Version History

| Date | DIND_VERSION | PYTHON_VERSIONS | UV_VERSION |
|------|-------------|-----------------|------------|
| 2026-02-21 | 29.2.1-dind-alpine3.23 | 3.13.12 3.12.10 3.11.12 | 0.9.30 |
| (previous) | 29.1.4-dind-alpine3.23 | 3.13.11 3.12.10 3.11.9 | 0.9.25 |

---

## Notes for the Agent

- Always check upstream sources directly — do not rely on cached knowledge for version numbers
- Never bump Python minor versions without explicit user instruction
- For uv: treat any 0.x.0 release as potentially breaking — read the changelog first
- The `pyproject.toml` uses semver ranges (`>=`) so it does not need updating for routine dependency bumps
- The `uv` binary is downloaded directly from GitHub releases using the musl target: `uv-x86_64-unknown-linux-musl.tar.gz` — verify this artifact exists for the new version before updating
