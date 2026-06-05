FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-client \
        sshpass \
        ca-certificates \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir ansible==10.7.0

COPY ansible/requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml

COPY ansible /workspace/ansible
COPY scripts/container-run.sh /workspace/scripts/container-run.sh
# Normalize line endings (strip any CR) so the entrypoint shebang never becomes
# `#!/usr/bin/env sh\r`, which fails with: env: 'sh\r': No such file or directory.
RUN sed -i 's/\r$//' /workspace/scripts/container-run.sh \
    && chmod +x /workspace/scripts/container-run.sh

ENTRYPOINT ["/workspace/scripts/container-run.sh"]
