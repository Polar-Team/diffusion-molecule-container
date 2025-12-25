#!/bin/bash
# Molecule wrapper script for compatibility with diffusion tool
# Activates uv virtual environment and runs molecule with all arguments

set -e

# Activate virtual environment
source /opt/uv/.venv/bin/activate

# Run molecule with all arguments
exec molecule "$@"
