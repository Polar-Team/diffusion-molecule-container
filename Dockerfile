ARG DIND_VERSION="29.0.4-dind-alpine3.22"
ARG PYTHON_VERSION="3.13.0"
ARG ADDITIONAL_PYTHON_VERSIONS=""

FROM docker:${DIND_VERSION}

ARG DIND_VERSION
ARG PYTHON_VERSION
ARG ADDITIONAL_PYTHON_VERSIONS

LABEL maintainer="Daniel Dalavurak"
LABEL org.label-schema.vendor="Polar Team"
LABEL org.label-schema.dind-version=${DIND_VERSION}
LABEL org.label-schema.python-version=${PYTHON_VERSION}
LABEL org.label-schema.additional-python-versions=${ADDITIONAL_PYTHON_VERSIONS}

# Set shell with pipefail for all RUN commands
SHELL ["/bin/sh", "-o", "pipefail", "-c"]

# Install system dependencies and build tools for pyenv
RUN apk add --no-cache --update \
  libffi-dev \
  git \
  curl \
  bash \
  gcc \
  musl-dev \
  make \
  openssl-dev \
  bzip2-dev \
  zlib-dev \
  readline-dev \
  sqlite-dev \
  xz-dev \
  tk-dev && \
  apk upgrade --available && \
  # Clean up unnecessary files to reduce image size
  rm -rf /var/cache/apk/* \
  /tmp/* \
  /root/.cache && \
  # Remove SSH server files (we only need git, not SSH server)
  rm -f /etc/ssh/moduli && \
  # Remove ZFS libraries if not needed (check if docker needs them)
  (rm -f /usr/lib/libzpool.so* /usr/lib/libzfs.so* || true)

# Install pyenv
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
RUN curl -fsSL https://pyenv.run | bash && \
  echo "eval \"\$(pyenv init -)\"" >> ~/.bashrc

# Install uv (fast Python package installer and manager)
# Copy certificate first as uv installation might need it
COPY certificate.pem /
RUN if [ -f "/certificate.pem" ]; then \
    cat /certificate.pem >> /etc/ssl/certs/ca-certificates.crt; \
  else \
    echo "No custom certificate provided"; \
  fi && \
  # Configure git (SSL verification disabled for corporate proxy environments)
  git config --global http.sslverify false && \
  # Download and install uv binary directly
  mkdir -p /root/.cargo/bin && \
  curl -LsSf https://github.com/astral-sh/uv/releases/download/0.5.11/uv-x86_64-unknown-linux-musl.tar.gz -o /tmp/uv.tar.gz && \
  tar -xzf /tmp/uv.tar.gz -C /tmp && \
  mv /tmp/uv-x86_64-unknown-linux-musl/uv /root/.cargo/bin/uv && \
  chmod +x /root/.cargo/bin/uv && \
  rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-musl

# Add uv to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:$PATH"

# Create uv project directory and copy files
RUN mkdir -p /opt/uv
COPY pyproject.toml /opt/uv/
COPY molecule-wrapper.sh /usr/local/bin/molecule-wrapper.sh

# Install Python using pyenv and dependencies using uv
# pyenv compiles Python from source (works on musl)
# uv manages packages (fast and modern)
WORKDIR /opt/uv
RUN eval "$(pyenv init -)" && \
  # Install primary Python version
  pyenv install ${PYTHON_VERSION} && \
  pyenv global ${PYTHON_VERSION} && \
  # Install additional Python versions if specified (space-separated)
  if [ -n "${ADDITIONAL_PYTHON_VERSIONS}" ]; then \
    for version in ${ADDITIONAL_PYTHON_VERSIONS}; do \
      echo "Installing additional Python version: $version" && \
      pyenv install "$version"; \
    done; \
  fi && \
  # Verify installation
  python --version && uv --version && \
  uv venv /opt/uv/.venv --python "$(pyenv which python)" && \
  uv pip install --python /opt/uv/.venv/bin/python -r pyproject.toml && \
  # Make wrapper executable and create molecule alias
  chmod +x /usr/local/bin/molecule-wrapper.sh && \
  ln -sf /usr/local/bin/molecule-wrapper.sh /usr/local/bin/molecule && \
  # Clean up cache and temporary files
  rm -rf /root/.cache \
  /tmp/* \
  /var/tmp/*

# Add venv to PATH so tools are available globally
ENV PATH="/opt/uv/.venv/bin:$PATH"

# Create docker group, ansible user, and setup directories
RUN addgroup -g 999 docker || true && \
  adduser -D -u 1000 -G docker -s /bin/bash ansible && \
  mkdir -p /home/ansible/.ansible/roles \
    /home/ansible/.ansible/collections \
    /home/ansible/.ansible/tmp \
    /opt/molecule && \
  chown -R ansible:docker /home/ansible/.ansible && \
  chmod -R 755 /home/ansible && \
  chmod 777 /opt/molecule && \
  chmod 1777 /tmp

# Copy and setup entrypoint script
COPY ./dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh

WORKDIR /opt/molecule

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]
