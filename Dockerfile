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
  apk upgrade --available

# Copy certificate if it exists
COPY certificate.pem /

RUN  [ -f "/certificate.pem" ] && cat /certificate.pem >> \
  /etc/ssl/certs/ca-certificates.crt || echo "No custom certificate provided"


# Configure git and Python pip
# Note: SSL verification disabled for corporate proxy environments
RUN git config --global http.sslverify false && \
  python3 -m pip config set global.cert /etc/ssl/certs/ca-certificates.crt

# Install Ansible Molecule and Docker plugin
# Using --break-system-packages due to Alpine's PEP 668 restrictions
RUN python3 -m pip install --break-system-packages -U \
  git+https://github.com/ansible-community/molecule@main && \
  python3 -m pip install --break-system-packages molecule-plugins[docker]

# Create docker group with GID 999 (standard docker group)
RUN addgroup -g 999 docker || true

# Create ansible user that can be overridden at runtime
# Using UID 1000 as default (will be overridden by --user flag)
RUN adduser -D -u 1000 -G docker -s /bin/bash ansible

# Create and set permissions for ansible home directory
RUN mkdir -p /home/ansible/.ansible/roles \
  /home/ansible/.ansible/collections \
  /home/ansible/.ansible/tmp && \
  chown -R ansible:docker /home/ansible/.ansible && \
  chmod -R 755 /home/ansible

# Create working directory
RUN mkdir -p /opt/molecule && chmod 777 /opt/molecule

# Ensure /tmp is writable (ansible-galaxy uses it)
#
RUN chmod 1777 /tmp

# Copy and setup entrypoint script
COPY ./dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh

WORKDIR /opt/molecule

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]
