# Contributing to Diffusion Molecule Container

Thank you for your interest in contributing to the Diffusion Molecule Container project! 🎉

This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Building and Testing](#building-and-testing)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)
- [Documentation](#documentation)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project adheres to the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior via GitHub issues or by contacting the maintainers.

## Getting Started

### Prerequisites

- Docker installed and running
- Git for version control
- Make (for using Makefile targets)
- Basic understanding of Docker, Ansible, and Molecule

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/diffusion-molecule-container.git
   cd diffusion-molecule-container
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/polar-team/diffusion-molecule-container.git
   ```

## Development Workflow

### Branching Strategy

- `main` - Stable production releases
- `dev-new-features` - Development branch for new features
- Feature branches - Create from `dev-new-features` for specific features

### Creating a Feature Branch

```bash
git checkout dev-new-features
git pull upstream dev-new-features
git checkout -b feature/your-feature-name
```

## Building and Testing

### Local Build

Build the image locally for your architecture:

```bash
make build-local
```

### Build and Save

Build and save the image as a tar archive:

```bash
make build-and-save
```

### Load Local Image

Load a previously saved image:

```bash
make load-local
```

### Multi-Architecture Build

Build for multiple architectures (requires buildx):

```bash
make build PLATFORMS="linux/amd64,linux/arm64"
```

### Testing with Diffusion CLI

After building locally, test with the diffusion CLI:

```bash
diffusion --image ghcr.io/polar-team/diffusion-molecule-container:latest-amd64 \
  --role /path/to/your/role \
  --converge
```

### Linting

Run hadolint to check Dockerfile quality:

```bash
docker run --rm -i hadolint/hadolint < Dockerfile
```

Or use the GitHub Actions workflow by pushing to your fork.

## Submitting Changes

### Commit Messages

Write clear, descriptive commit messages following this format:

```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat: add support for Python 3.13

- Migrate from system Python to pyenv for version management
- Add ADDITIONAL_PYTHON_VERSIONS build arg for multi-version support
- Update documentation with new configuration options

Closes #123
```

### Pull Request Process

1. **Update your branch** with the latest changes from upstream:
   ```bash
   git fetch upstream
   git rebase upstream/dev-new-features
   ```

2. **Test your changes** thoroughly:
   - Build the image locally
   - Test with diffusion CLI
   - Run hadolint checks
   - Verify documentation is updated

3. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a Pull Request**:
   - Go to the GitHub repository
   - Click "New Pull Request"
   - Select `dev-new-features` as the base branch
   - Provide a clear title and description
   - Reference any related issues

5. **PR Requirements**:
   - All CI checks must pass (hadolint, build tests)
   - Code follows project conventions
   - Documentation is updated
   - Changelog is updated (if applicable)
   - At least one maintainer approval

6. **Address Review Feedback**:
   - Make requested changes
   - Push updates to your branch
   - Respond to comments

## Coding Standards

### Dockerfile Best Practices

- Follow [hadolint](https://github.com/hadolint/hadolint) recommendations
- Use multi-stage builds when appropriate
- Minimize layer count by combining RUN commands
- Clean up temporary files in the same layer they're created
- Pin versions for external dependencies
- Use proper label schema (`org.label-schema.*`)
- Set SHELL with pipefail for RUN commands with pipes
- Use WORKDIR instead of `cd` commands

### Shell Scripts

- Use shellcheck for validation
- Include proper error handling
- Add comments for complex logic
- Use meaningful variable names

### Python Dependencies

- Update `pyproject.toml` for new dependencies
- Test with multiple Python versions if applicable
- Document version requirements

## Documentation

### What to Document

- New features and configuration options
- Breaking changes
- Migration guides
- Examples and use cases

### Where to Document

- **README.md**: Overview, quick start, basic usage
- **docs/CONFIGURATION.md**: Detailed configuration options
- **docs/CHANGELOG.md**: Version history and changes
- **Code comments**: Complex logic and non-obvious decisions

### Documentation Style

- Use clear, concise language
- Include code examples
- Add links to related documentation
- Keep formatting consistent

## Reporting Issues

### Bug Reports

When reporting bugs, include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**:
  - Docker version
  - Host OS and architecture
  - Diffusion CLI version (if applicable)
  - Image version/tag
- **Logs**: Relevant error messages or logs
- **Additional Context**: Screenshots, configuration files, etc.

### Feature Requests

When requesting features, include:

- **Use Case**: Why this feature is needed
- **Proposed Solution**: How you envision it working
- **Alternatives**: Other solutions you've considered
- **Additional Context**: Examples, mockups, etc.

## Development Tips

### Testing Python Version Changes

```bash
# Build with additional Python versions
docker build \
  --build-arg PYTHON_VERSION=3.13.0 \
  --build-arg ADDITIONAL_PYTHON_VERSIONS="3.12.0 3.11.0" \
  -t test-image .

# Verify installed versions
docker run --rm test-image pyenv versions
```

### Debugging Build Issues

```bash
# Build with no cache to ensure clean build
docker build --no-cache -t test-image .

# Run interactive shell in the image
docker run --rm -it test-image /bin/bash
```

### Checking Image Efficiency

```bash
# Use dive to analyze image layers
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest test-image
```

## Questions?

If you have questions or need help:

- Open a GitHub issue with the `question` label
- Check existing issues and discussions
- Review the documentation in the `docs/` folder

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (check LICENSE file).

---

Thank you for contributing to Diffusion Molecule Container! Your efforts help make Molecule testing more accessible and enjoyable for everyone. 🚀
