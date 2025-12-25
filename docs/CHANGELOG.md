# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Migrated from pip to uv for Python package management
- Added `pyproject.toml` for dependency management
- Added configurable Python version via build args (default: 3.12)
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

### Changed
- Organized Python environment in `/opt/molecule/uv/` directory
- Virtual environment now at `/opt/molecule/uv/.venv/`
- Removed system Python packages (python3, py3-pip)
- Removed yamllint and ansible-lint from apk (now managed by uv)
- Optimized Dockerfile for smaller image size
  - Combined RUN commands to reduce layers
  - Removed unnecessary files (SSH server, ZFS libraries)
  - Cleaned up caches and temporary files
- Updated Makefile to support Python version override

### Fixed
- Molecule wrapper now maintains current working directory
- Certificate handling simplified (no pip config needed)

### Removed
- Removed `--break-system-packages` workaround (uv handles this properly)
- Removed pip configuration for certificates

## [1.0.7] - 2024-12-25

### Added
- Initial release with Docker-in-Docker support
- Ansible Molecule and Docker plugin
- Custom CA certificate support
- Git configuration for corporate proxies

### Changed
- Base image: docker:29.0.4-dind-alpine3.22

[Unreleased]: https://github.com/polar-team/diffusion-molecule-container/compare/v1.0.7...HEAD
[1.0.7]: https://github.com/polar-team/diffusion-molecule-container/releases/tag/v1.0.7
