ARG DIND_VERSION="29.0.4-dind-alpine3.22"

FROM docker:${DIND_VERSION}

ARG DIND_VERSION

LABEL maintainer="Daniel Dalavurak"
LABEL org="Polar Team"
LABEL dind_version=${DIND_VERSION}

# Install system dependencies
RUN apk add --no-cache --update \
  python3 \
  py3-pip \
  libffi-dev \
  git \
  yamllint \
  ansible-lint && \
  apk upgrade --available && \
  # Clean up unnecessary files to reduce image size
  rm -rf /var/cache/apk/* \
  /tmp/* \
  /root/.cache \
  # Remove SSH server files (we only need git, not SSH server)
  /etc/ssh/moduli \
  # Remove ZFS libraries if not needed (check if docker needs them)
  /usr/lib/libzpool.so* \
  /usr/lib/libzfs.so* || true

# Copy certificate if it exists and configure git/pip
COPY certificate.pem /
RUN [ -f "/certificate.pem" ] && cat /certificate.pem >> \
  /etc/ssl/certs/ca-certificates.crt || echo "No custom certificate provided" && \
  # Configure git and Python pip (SSL verification disabled for corporate proxy environments)
  git config --global http.sslverify false && \
  python3 -m pip config set global.cert /etc/ssl/certs/ca-certificates.crt

# Install Ansible Molecule and Docker plugin
# Using --break-system-packages due to Alpine's PEP 668 restrictions
RUN python3 -m pip install --no-cache-dir --break-system-packages -U \
  git+https://github.com/ansible-community/molecule@main && \
  python3 -m pip install --no-cache-dir --break-system-packages molecule-plugins[docker] && \
  # Clean up pip cache and temporary files
  rm -rf /root/.cache/pip \
  /tmp/* \
  /var/tmp/*

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
