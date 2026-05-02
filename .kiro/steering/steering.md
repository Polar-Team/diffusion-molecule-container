---
inclusion: always
---

# Diffusion Molecule Container — Technical Steering Document

## Project Overview

Diffusion Molecule Container is a Docker-in-Docker (DinD) container image designed for running Ansible Molecule tests. It provides a complete, self-contained testing environment with Docker, Ansible, Molecule, linting tools, and Python — built for both AMD64 and ARM64 architectures.

- **Image**: `ghcr.io/polar-team/diffusion-molecule-container`
- **Base**: Alpine-based Docker DinD (`docker:<version>-dind-alpine`)
- **Python management**: pyenv (compile from source) + uv (fast package installer)
- **Dependency config**: `pyproject.toml`
- **Registry**: GitHub Container Registry (GHCR)
- **License**: MIT
- **Maintainer**: Daniel Dalavurak

## Key Features

- Docker-in-Docker on Alpine Linux
- Multi-Python version support via pyenv (3.13, 3.12, 3.11)
- uv for fast Python dependency management
- Ansible Molecule (latest from main branch)
- ansible-lint and yamllint pre-installed
- Custom CA certificate support for corporate environments
- Indexed Git credential management (`GIT_USER_<N>`, `GIT_PASSWORD_<N>`, `GIT_URL_<N>`)
- Multi-platform builds (linux/amd64, linux/arm64)
- Dive image efficiency validation (≥96% target)

## Development Rule — dev-new-features

All agent changes, new feature implementation, refactoring, and experimental work MUST be done inside the `dev-new-features/` directory. This directory mirrors the main project structure and acts as the active development branch within the repo.

```
dev-new-features/
├── .github/workflows/     # CI/CD workflows
├── .kiro/specs/           # Kiro specs
├── docs/                  # Documentation (CHANGELOG, CONFIGURATION)
├── .dive-ci               # Dive efficiency rules
├── .dockerignore
├── dockerd-entrypoint.sh  # DinD entrypoint with TLS + git creds
├── Dockerfile             # Multi-stage build
├── Makefile               # Build, publish, test targets
├── molecule-wrapper.sh    # Molecule venv activation wrapper
├── pyproject.toml         # Python dependencies
├── renovate.json          # Automated dependency updates
└── uv-install-and-sync.sh # Runtime pyproject.toml injection from diffusion
```

**Do NOT modify files in the root-level project directory directly.** Always work in `dev-new-features/` unless explicitly told otherwise.

## Project Structure

```
diffusion-molecule-container/
├── .github/
│   ├── workflows/
│   │   ├── build-and-publish.yml   # Multi-arch build + push to GHCR
│   │   ├── cleanup.yml             # Image cleanup
│   │   ├── dockerfile-updater.yml  # Automated Dockerfile updates
│   │   └── lint.yml                # Hadolint Dockerfile linting
│   └── dependabot.yml              # Dependabot config
├── cache/                          # Local buildx cache (OCI layout)
├── docs/
│   ├── CHANGELOG.md
│   └── CONFIGURATION.md
├── .dive-ci                        # Dive image efficiency thresholds
├── buildkitd.toml                  # BuildKit registry CA config
├── certificate.pem                 # Custom CA cert (optional)
├── Dockerfile                      # Multi-stage DinD image
├── dockerd-entrypoint.sh           # Entrypoint: TLS, git creds, dockerd
├── Makefile                        # Build/publish/test automation
├── molecule-wrapper.sh             # Wrapper: activates venv, runs molecule
├── pyproject.toml                  # Python deps (ansible, molecule, linters)
├── renovate.json                   # Renovate bot config for Alpine deps
└── uv-install-and-sync.sh          # Runtime dependency sync from diffusion
```

## Dockerfile Architecture

Multi-stage build:

1. **Builder stage** — Installs pyenv, compiles Python versions, installs uv binary
2. **Final stage** — Copies pyenv + uv from builder, installs runtime Alpine deps, creates venv, installs Python packages via uv, sets up molecule wrapper and entrypoint

Key build args:

| Arg | Default | Description |
|---|---|---|
| `DIND_VERSION` | `29.4.0-dind-alpine3.23` | Docker DinD base image version |
| `PYTHON_VERSIONS` | `3.13.13 3.12.13 3.11.15` | Space-separated Python versions (first is primary) |
| `UV_VERSION` | `0.9.30` | uv package manager version |

## Key Scripts

| Script | Location in container | Purpose |
|---|---|---|
| `molecule-wrapper.sh` | `/usr/local/bin/molecule` | Activates uv venv, runs `molecule` with all args |
| `uv-install-and-sync.sh` | `/usr/local/bin/uv-sync` | Decodes base64 `PYPROJECT_TOML_CONTENT` env var, writes to `/opt/uv/pyproject.toml`, reinstalls deps |
| `dockerd-entrypoint.sh` | `/usr/local/bin/dockerd-entrypoint.sh` | Configures indexed git credentials, generates TLS certs, starts dockerd |

## Python Dependencies (pyproject.toml)

```toml
[project]
requires-python = ">=3.11"
dependencies = [
    "ansible>=10.0.0",
    "ansible-lint>=24.0.0",
    "molecule>=24.0.0",
    "yamllint>=1.35.0",
    "molecule-plugins[docker]>=23.5.0",
    "docker>=6.0.0"
]

[tool.uv.sources]
molecule = { git = "https://github.com/ansible-community/molecule", branch = "main" }
```

## Environment Variables

| Variable | Description |
|---|---|
| `DOCKER_TLS_CERTDIR` | TLS certificate directory (set by base image) |
| `GIT_USER_<N>` | Git username for repository N |
| `GIT_PASSWORD_<N>` | Git password/token for repository N |
| `GIT_URL_<N>` | Git URL for repository N |
| `PYPROJECT_TOML_CONTENT` | Base64-encoded pyproject.toml for runtime injection |
| `PYTHON_PINNED_VERSION` | Python version for uv-sync venv recreation |

## Image Tags

Platform-specific tags (no combined multi-platform manifest):

- `latest-amd64` / `latest-arm64`
- `<version>-amd64` / `<version>-arm64`
- `*-test` suffix for test builds (`TEST_CONTAINER=true`)

## Build & Publish (Makefile)

| Target | Description |
|---|---|
| `make help` | Show all available targets |
| `make publish` | Full pipeline: check cert → check cache → setup buildx → login → build+push |
| `make build-and-push-separate` | Build and push per-architecture tags to GHCR |
| `make test-local` | Build and test image locally |
| `make build-local` | Build image locally as `<name>:local` |
| `make build-and-save` | Build and save to tar file |
| `make load-local` | Load saved tar image |
| `make setup-buildx` | Create Docker Buildx multi-platform builder |
| `make login` | Login to GHCR |
| `make check_cache` | Initialize build cache if missing |
| `make check_certificate` | Create empty cert if none exists |
| `make clean` | Remove buildx builder |
| `make clean-local` | Remove local images and tar files |
| `make show-platforms` | Show configured platforms and tags |

Overridable variables:

```bash
make publish DIND_VERSION=29.0.5-dind-alpine3.22
make publish PYTHON_VERSIONS="3.13.0 3.12.0"
make publish UV_VERSION=0.9.30
```

## Image Efficiency

Dive CI thresholds (`.dive-ci`):

- Minimum efficiency: 96%
- Max wasted bytes: 25MB
- Max wasted percent: 10%

## Automated Updates

- **Dependabot**: GitHub Actions and Docker base image updates (daily)
- **Renovate**: Alpine package version pinning via regex custom manager
