# Configuration Guide

## Overview

This container uses `uv` to manage Python and all dependencies. Everything is configured via `pyproject.toml` for easy version management and reproducibility.

## Directory Structure

```
/opt/molecule/
├── uv/
│   ├── pyproject.toml          # Python dependencies configuration
│   ├── .venv/                  # Virtual environment
│   │   ├── bin/
│   │   │   ├── python          # Python interpreter
│   │   │   ├── molecule        # Molecule CLI
│   │   │   ├── ansible         # Ansible CLI
│   │   │   ├── ansible-lint    # Ansible Lint
│   │   │   └── yamllint        # YAML Lint
│   │   └── lib/                # Python packages
└── (your molecule projects)    # User workspace
```

## Python Version Configuration

### Build-time Configuration

Specify Python version when building the image:

```bash
# Using Docker
docker build --build-arg PYTHON_VERSION=3.13 -t my-molecule-container .

# Using Makefile
make publish PYTHON_VERSION=3.13
```

### Default Version

The default Python version is `3.12` (specified in `pyproject.toml`).

## Dependency Configuration

### pyproject.toml

All Python dependencies are defined in `pyproject.toml`:

```toml
[project]
name = "diffusion-molecule-container"
version = "1.0.0"
description = "Docker-in-Docker container for Ansible Molecule testing"
requires-python = ">=3.11"
dependencies = [
    "ansible>=10.0.0",
    "ansible-lint>=24.0.0",
    "molecule>=24.0.0",
    "molecule-plugins[docker]>=23.5.0",
    "yamllint>=1.35.0",
]

[tool.uv]
python-version = "3.12"

[tool.uv.sources]
# Use latest molecule from main branch
molecule = { git = "https://github.com/ansible-community/molecule", branch = "main" }
```

### Customizing Dependencies

To customize dependencies, modify `pyproject.toml` and rebuild:

```toml
dependencies = [
    "ansible>=9.0.0",              # Pin to specific version
    "ansible-lint>=24.5.0",        # Update minimum version
    "molecule>=24.0.0",
    "molecule-plugins[docker]>=23.5.0",
    "yamllint>=1.35.0",
    "jmespath>=1.0.0",             # Add new dependency
]
```

### Using Specific Molecule Version

To use a specific Molecule version instead of latest from git:

```toml
[project]
dependencies = [
    "ansible>=10.0.0",
    "ansible-lint>=24.0.0",
    "molecule==24.2.0",            # Pin to specific version
    "molecule-plugins[docker]>=23.5.0",
    "yamllint>=1.35.0",
]

# Remove or comment out the git source
# [tool.uv.sources]
# molecule = { git = "https://github.com/ansible-community/molecule", branch = "main" }
```

## Docker-in-Docker Version

### Build-time Configuration

Specify DinD version when building:

```bash
# Using Docker
docker build --build-arg DIND_VERSION=29.0.5-dind-alpine3.22 -t my-molecule-container .

# Using Makefile
make publish DIND_VERSION=29.0.5-dind-alpine3.22
```

### Default Version

The default DinD version is `29.0.4-dind-alpine3.22`.

## Custom CA Certificate

For corporate environments with custom CA certificates:

1. Place your certificate in `certificate.pem` in the build directory
2. The Dockerfile will automatically add it to the system trust store
3. Git will be configured to use the custom certificate

If no certificate is needed, an empty `certificate.pem` file is created automatically.

## Environment Variables

The container supports these environment variables:

### Git Configuration

- Git SSL verification is disabled by default for corporate proxy environments
- To enable SSL verification, modify the Dockerfile or override in your environment

### Python Environment

- `PATH` includes `/opt/molecule/uv/.venv/bin` for direct access to all tools
- Virtual environment is automatically activated via the molecule wrapper

## Molecule Wrapper

The container includes a wrapper script at `/usr/local/bin/molecule` that:

1. Activates the uv virtual environment
2. Runs molecule with all passed arguments
3. Maintains the current working directory

This ensures compatibility with the diffusion tool and other automation.

## Updating Dependencies

### Runtime Updates (Inside Container)

```bash
# Enter the container
docker exec -it <container-id> /bin/bash

# Navigate to uv directory
cd /opt/molecule/uv

# Update specific package
uv pip install --upgrade ansible

# Update all packages
uv pip install --upgrade -r pyproject.toml
```

### Build-time Updates

1. Modify `pyproject.toml`
2. Rebuild the image:
   ```bash
   docker build -t my-molecule-container .
   ```

## Lock File (Optional)

To create a lock file for reproducible builds:

```bash
# Generate uv.lock
cd /opt/molecule/uv
uv lock

# Install from lock file
uv sync
```

Add `uv.lock` to your repository for consistent dependency versions across builds.

## GitHub Actions Configuration

The workflow supports version overrides via environment variables:

```yaml
env:
  PYTHON_VERSION: "3.13"  # Override Python version
  
build-args: |
  DIND_VERSION=29.0.5-dind-alpine3.22
  PYTHON_VERSION=${{ env.PYTHON_VERSION }}
```

## Troubleshooting

### Check Installed Versions

```bash
# Python version
python --version

# Molecule version
molecule --version

# Ansible version
ansible --version

# List all installed packages
uv pip list
```

### Virtual Environment Issues

If the virtual environment is not activated:

```bash
source /opt/molecule/uv/.venv/bin/activate
```

### Dependency Conflicts

If you encounter dependency conflicts:

```bash
cd /opt/molecule/uv
uv pip install --force-reinstall -r pyproject.toml
```

## Best Practices

1. **Pin versions** for production use
2. **Use lock files** for reproducible builds
3. **Test updates** in a separate environment before deploying
4. **Document custom dependencies** in your project README
5. **Keep base images updated** (DinD and Alpine versions)

## Examples

### Custom Build with Specific Versions

```bash
docker build \
  --build-arg PYTHON_VERSION=3.13 \
  --build-arg DIND_VERSION=29.0.5-dind-alpine3.22 \
  -t ghcr.io/polar-team/diffusion-molecule-container:custom \
  .
```

### Using with Diffusion Tool

```bash
# The molecule wrapper ensures compatibility
diffusion molecule test --scenario-name default
```

### Adding Custom Python Packages

Edit `pyproject.toml`:

```toml
dependencies = [
    "ansible>=10.0.0",
    "ansible-lint>=24.0.0",
    "molecule>=24.0.0",
    "molecule-plugins[docker]>=23.5.0",
    "yamllint>=1.35.0",
    "jmespath>=1.0.0",        # For JSON parsing
    "netaddr>=0.10.0",        # For network calculations
    "requests>=2.31.0",       # For HTTP requests
]
```

Rebuild the image to apply changes.
