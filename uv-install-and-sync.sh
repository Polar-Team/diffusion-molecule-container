#!/bin/sh
# UV installation and synchronization script for diffusion tool
# Handle pyproject.toml configuration passed from diffusion

uv_update_command() {
  cd /opt/uv && echo "${PYTHON_PINNED_VERSION}" >.python-version
  uv venv /opt/uv/.venv --python "$(pyenv which python)"
  /root/.cargo/bin/uv pip install --python /opt/uv/.venv/bin/python -r pyproject.toml
  rm -rf "/opt/uv/.venv/lib/python${PYTHON_PINNED_VERSION}/site-packages/ansible_collections"
}

pyproject_toml_creation_command() {
  echo "${PYPROJECT_TOML_CONTENT}" | base64 -d >/opt/uv/pyproject.toml
}

if [ -n "${PYPROJECT_TOML_CONTENT:-}" ]; then
  echo "Applying custom pyproject.toml configuration from diffusion..."
  # Decode base64 content and write to /opt/uv/pyproject.toml
  if pyproject_toml_creation_command; then
    echo "Custom pyproject.toml applied successfully"
    # Reinstall dependencies with new configuration
    echo "Reinstalling Python dependencies..."
    cd /opt/uv || echo "Error: Failed to change directory to /opt/uv" >&2
    if uv_update_command; then
      echo "Dependencies reinstalled successfully"
    else
      echo "Warning: Failed to reinstall dependencies, using existing packages" >&2
    fi
  else
    echo "Warning: Failed to decode pyproject.toml content, using default configuration" >&2
  fi
fi
