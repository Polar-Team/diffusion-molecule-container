# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.8] - 2024-12-25

### Added
- Migrated from pip to uv for Python package management
- Added pyenv for full Python version control on Alpine
- Added `pyproject.toml` for dependency management
- Added configurable Python version via build args (default: 3.13.0)
- Added support for multiple Python versions via ADDITIONAL_PYTHON_VERSIONS
- Added molecule wrapper script for diffusion tool compatibility
- Added GitHub Actions workflow for automated builds
  - Parallel matrix builds for amd64 and arm64
  - GitHub Actions cache for faster builds
  - Multi-arch manifest creation
  - Dive analysis for image efficiency validation
- Added hadolint workflow for Dockerfile linting
- Added Dependabot for automated dependency updates
  - Daily checks for GitHub Actions updates
  - Daily checks for Docker base image updates
- Added comprehensive configuration documentation
- Added image optimization spec (97% efficiency achieved)
- Added Makefile targets for local testing (build-local, build-and-save, load-local)

### Changed
- Organized Python environment in `/opt/uv/` directory
- Virtual environment now at `/opt/uv/.venv/`
- Python version management via pyenv (compiles from source)
- Default Python version: 3.13.0 (was 3.12 from Alpine)
- Optimized Dockerfile for smaller image size
  - Combined RUN commands to reduce layers
  - Removed unnecessary files (SSH server, ZFS libraries)
  - Cleaned up caches and temporary files
- Updated Makefile to support Python version and additional versions override
- Updated GitHub Actions to use Python 3.13.0

### Fixed
- Molecule wrapper now maintains current working directory
- Certificate handling simplified (no pip config needed)

### Removed
- Removed `--break-system-packages` workaround (uv handles this properly)
- Removed pip configuration for certificates
- Removed `python-version` from pyproject.toml (not a valid uv field)

## [1.0.7] - 2024-12-25

### Added
- Initial release with Docker-in-Docker support
- Ansible Molecule and Docker plugin
- Custom CA certificate support
- Git configuration for corporate proxies

### Changed
- Base image: docker:29.0.4-dind-alpine3.22

[1.0.8]: https://github.com/polar-team/diffusion-molecule-container/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/polar-team/diffusion-molecule-container/releases/tag/v1.0.7
