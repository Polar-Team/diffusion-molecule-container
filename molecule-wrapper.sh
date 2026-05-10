#!/bin/bash
# Molecule wrapper script for compatibility with diffusion tool
# Activates uv virtual environment and runs molecule with all arguments

set -e

# If a runtime certificate was mounted, inject it into the trust stores
if [ -f "/certificate.pem" ] && [ -s "/certificate.pem" ]; then
  # Append to system CA bundle if not already present
  if ! grep -qF "$(head -1 /certificate.pem)" /etc/ssl/certs/ca-certificates.crt 2>/dev/null; then
    cat /certificate.pem >> /etc/ssl/certs/ca-certificates.crt 2>/dev/null || true
  fi

  # Append to certifi bundle if not already present
  CERTIFI_BUNDLE=$(/opt/uv/.venv/bin/python -c "import certifi; print(certifi.where())" 2>/dev/null || true)
  if [ -n "$CERTIFI_BUNDLE" ] && [ -f "$CERTIFI_BUNDLE" ]; then
    if ! grep -qF "$(head -1 /certificate.pem)" "$CERTIFI_BUNDLE" 2>/dev/null; then
      cat /certificate.pem >> "$CERTIFI_BUNDLE" 2>/dev/null || true
    fi
  fi
fi

# Ensure SSL environment variables point to system CA bundle
export REQUESTS_CA_BUNDLE=${REQUESTS_CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}
export SSL_CERT_FILE=${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}
export CURL_CA_BUNDLE=${CURL_CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}

# Activate virtual environment
source /opt/uv/.venv/bin/activate

# Run molecule with all arguments
exec molecule "$@"
