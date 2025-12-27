ARG DIND_VERSION="29.0.4-dind-alpine3.22"
ARG PYTHON_VERSIONS="3.13.11 3.12.10 3.11.9"


FROM docker:${DIND_VERSION} AS builder

ARG PYTHON_VERSIONS

# Setup pyenv
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# Install system dependencies and build tools for pyenv
RUN apk add --no-cache --update \
  libffi-dev=3.4.8-r0 \
  git=2.49.1-r0 \
  curl=8.14.1-r2 \
  bash=5.2.37-r0 \
  gcc=14.2.0-r6 \
  musl-dev=1.2.5-r10 \
  make=4.4.1-r3 \
  openssl-dev=3.5.4-r0 \
  bzip2-dev=1.0.8-r6 \
  zlib-dev=1.3.1-r2 \
  readline-dev=8.2.13-r1 \
  sqlite-dev=3.49.2-r1 \
  xz-dev=5.8.1-r0 \
  tk-dev=8.6.16-r0 \
  patch=2.8-r0

# Set shell with pipefail for all RUN commands
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Install pyenv
RUN curl -fsSL https://pyenv.run | bash && \
  echo "eval \"\$(pyenv init -)\"" >> ~/.bashrc

# Install pyenv python required versions
RUN eval "$(pyenv init -)" && \
  # Parse PYTHON_VERSIONS and get first element as primary
  PRIMARY_VERSION=$(echo "${PYTHON_VERSIONS}" | cut -d' ' -f1) && \
  # Install primary Python version
  echo "Installing primary Python version: $PRIMARY_VERSION" && \
  pyenv install "$PRIMARY_VERSION" && \
  pyenv global "$PRIMARY_VERSION" && \
  echo "${PRIMARY_VERSION}" > /root/.python-version && \
  # Install additional Python versions from PYTHON_VERSIONS
  for version in ${PYTHON_VERSIONS}; do \
  if [ "$version" != "$PRIMARY_VERSION" ]; then \
  echo "Installing additional Python version: $version" && \
  pyenv install "$version"; \
  fi; \
  done


# Installing uv
RUN  curl -LsSf \
  https://github.com/astral-sh/uv/releases/download/0.5.11/uv-x86_64-unknown-linux-musl.tar.gz \
  -o /tmp/uv.tar.gz && \
  tar -xzf /tmp/uv.tar.gz -C /tmp && \
  [ -d  "/root/.cargo/bin/" ] || mkdir -p  /root/.cargo/bin && \
  mv /tmp/uv-x86_64-unknown-linux-musl/uv /root/.cargo/bin/uv && \
  chmod +x /root/.cargo/bin/uv && \
  rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-musl


FROM docker:${DIND_VERSION}

ARG DIND_VERSION
ARG PYTHON_VERSION
ARG ADDITIONAL_PYTHON_VERSIONS

LABEL maintainer="Daniel Dalavurak"
LABEL org.label-schema.vendor="Polar Team"
LABEL org.label-schema.dind-version=${DIND_VERSION}
LABEL org.label-schema.python-version=${PYTHON_VERSION}
LABEL org.label-schema.additional-python-versions=${ADDITIONAL_PYTHON_VERSIONS}

# Setup pyenv
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# Set shell with pipefail for all RUN commands
SHELL ["/bin/sh", "-o", "pipefail", "-c"]
RUN apk add --no-cache --update \
  git=2.49.1-r0 \
  bash=5.2.37-r0 \
  musl=1.2.5-r10 \
  libffi=3.4.8-r0 \
  openssl=3.5.4-r0 \
  bzip2=1.0.8-r6 \
  zlib=1.3.1-r2  \
  readline=8.2.13-r1 \
  xz=5.8.1-r0 \
  tk=8.6.16-r0

#  Upgrade all installed packages to their latest versions

RUN  apk upgrade --available && \
  # Clean up unnecessary files to reduce image size
  rm -rf /var/cache/apk/* \
  /tmp/* \
  /root/.cache

# Remove SSH server files (we only need git, not SSH server)
RUN  rm -f /etc/ssh/moduli

# Remove ZFS libraries if not needed (check if docker needs them)
RUN  (rm -f /usr/lib/libzpool.so* /usr/lib/libzfs.so* || true)

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
  mkdir -p /root/.cargo/bin

COPY --from=builder /root/.cargo/bin/uv /root/.cargo/bin/uv

RUN chmod +x /root/.cargo/bin/uv

# Add venv to PATH so tools are available globally
ENV PATH="/opt/uv/.venv/bin:$PATH"

# Add uv to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:$PATH"

# Create uv project directory and copy files
RUN mkdir -p /opt/uv
COPY pyproject.toml /opt/uv/
COPY --from=builder /root/.python-version /opt/uv/.python-version
COPY --from=builder /root/.pyenv /root/.pyenv
COPY molecule-wrapper.sh /usr/local/bin/molecule-wrapper.sh
COPY uv-install-and-sync.sh /usr/local/bin/uv-install-and-sync.sh

# Install Python using pyenv and dependencies using uv
# pyenv compiles Python from source (works on musl)
# uv manages packages (fast and modern)
RUN eval "$(pyenv init -)" && \
  # Verify pyenv was copied successfully
  pyenv --version && \
  # Verify Python installations were copied from builder
  pyenv versions && \
  python --version && \
  # Verify uv is available
  uv --version && \
  # Create virtual environment and install dependencies
  uv venv /opt/uv/.venv --python "$(pyenv which python)" && \
  uv pip install --python /opt/uv/.venv/bin/python -r /opt/uv/pyproject.toml && \
  # Make wrapper executable and create molecule alias
  chmod +x /usr/local/bin/molecule-wrapper.sh && \
  ln -sf /usr/local/bin/molecule-wrapper.sh /usr/local/bin/molecule && \
  chmod +x /usr/local/bin/uv-install-and-sync.sh && \
  ln -sf /usr/local/bin/uv-install-and-sync.sh /usr/local/bin/uv-sync && \
  # Clean up cache and temporary files
  rm -rf /root/.cache \
  /tmp/* \
  /var/tmp/*

RUN rm -rf /opt/uv/.venv/lib/python3.13/site-packages/ansible_collections

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
