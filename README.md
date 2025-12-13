# Diffusion Molecule Container

A Docker-in-Docker (DinD) container image designed for running Ansible Molecule tests.  This image provides a complete testing environment with Docker, Ansible, Molecule, and all necessary dependencies.

## Features

- 🐳 **Docker-in-Docker**:  Built on Alpine-based Docker DinD image
- 🧪 **Ansible Molecule**:  Latest version from the main branch
- 🔧 **Pre-configured Tools**: Includes ansible-lint, yamllint, and Python 3
- 🔐 **Custom Certificate Support**: Add your own CA certificates for corporate environments
- 🌐 **Git Credential Management**: Support for multiple Git repositories with authentication
- 🏗️ **Multi-platform**:  Built for both AMD64 and ARM64 architectures

## Quick Start

### Pull the Image

```bash
# For AMD64
docker pull ghcr.io/polar-team/diffusion-molecule-container:latest-amd64

# For ARM64
docker pull ghcr.io/polar-team/diffusion-molecule-container:latest-arm64
```

### Run Molecule Tests

```bash
docker run --privileged -v $(pwd):/opt/molecule \
  ghcr.io/polar-team/diffusion-molecule-container:latest-amd64 \
  molecule test
```

## Building and Publishing

This project includes a comprehensive Makefile for building and publishing multi-platform container images to GitHub Container Registry (GHCR).

### Available Make Targets

```
Usage: make [target]

Available targets:
  build-and-push-separate  Build and push with separate tags per architecture
  check_cache             Check and initialize build cache
  check_certificate       Check for custom certificate
  clean                   Remove buildx builder
  help                    Show this help message
  login                   Login to GitHub Container Registry
  publish                 Publish with separate architecture tags
  setup-buildx            Setup Docker Buildx for multi-platform builds
  setup-buildx-extra-conf Setup Docker Buildx for multi-platform builds
  show-platforms          Show configured platforms
  test-local              Build and test image locally for current platform
```

### Common Workflows

#### View Available Commands
```bash
make help
```

#### Test Locally
Build and test the image on your current platform:
```bash
make test-local
```

#### Publish to GHCR
Build and push multi-platform images (requires authentication):
```bash
export GITHUB_TOKEN=your_token
export GITHUB_ACTOR=your_username
make publish
```

#### Show Platform Information
```bash
make show-platforms
```

#### Clean Up Build Environment
```bash
make clean
```

## Configuration

### Custom Certificates

To add a custom CA certificate (useful for corporate proxies):

1. Place your certificate as `certificate.pem` in the repository root
2. The build process will automatically include it in the image

### Git Credentials

Configure Git credentials at runtime using indexed environment variables:

```bash
docker run --privileged \
  -e GIT_USER_1="username" \
  -e GIT_PASSWORD_1="token" \
  -e GIT_URL_1="github.com/your-org" \
  -e GIT_USER_2="another_user" \
  -e GIT_PASSWORD_2="another_token" \
  -e GIT_URL_2="gitlab.com/your-org" \
  -v $(pwd):/opt/molecule \
  ghcr.io/polar-team/diffusion-molecule-container:latest-amd64 \
  molecule test
```

## Image Tags

The image is published with platform-specific tags: 

- `latest-amd64` - Latest AMD64 build
- `latest-arm64` - Latest ARM64 build
- `<version>-amd64` - Specific version for AMD64
- `<version>-arm64` - Specific version for ARM64

**Note**: There is no combined multi-platform `latest` tag.  Always specify the platform suffix.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DOCKER_TLS_CERTDIR` | Directory for Docker TLS certificates | Set by base image |
| `GIT_USER_<N>` | Git username for repository N | - |
| `GIT_PASSWORD_<N>` | Git password/token for repository N | - |
| `GIT_URL_<N>` | Git URL for repository N | - |

## Development

### Prerequisites

- Docker with Buildx support
- Make
- Git
- GitHub account with GHCR access (for publishing)

### Build Configuration

Key variables in the Makefile:

- `REGISTRY`: Container registry (default: `ghcr.io`)
- `ORG`: Organization name (default: `polar-team`)
- `IMAGE_NAME`: Image name (default: `diffusion-molecule-container`)
- `DIND_VERSION`: Docker-in-Docker base image version (default: `29.0.4-dind-alpine3.22`)
- `PLATFORMS`: Target platforms (default: `linux/amd64,linux/arm64`)

## What's Included

- **Docker**:  Latest Docker-in-Docker on Alpine Linux
- **Python 3**: With pip and necessary libraries
- **Ansible Molecule**:  Latest from main branch
- **Molecule Docker Plugin**: For container-based testing
- **ansible-lint**:  Ansible best practices checker
- **yamllint**:  YAML syntax validator
- **Git**:  With SSL configuration options

## Use Cases

- 🧪 Running Ansible Molecule tests in CI/CD pipelines
- 🔄 Testing Ansible roles with Docker-based scenarios
- 🏢 Corporate environments requiring custom CA certificates
- 🔐 Projects needing authenticated access to multiple Git repositories
- 🚀 Multi-platform Ansible role development and testing

## License

This project is maintained by the Polar Team. 

## Maintainer

Daniel Dalavurak

## Contributing

Contributions are welcome!  Please feel free to submit issues or pull requests.