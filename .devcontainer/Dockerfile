FROM alexfariakof/node-base:latest AS base
USER root
ARG USERNAME=node
ENV USERNAME=${USERNAME}
ARG WORKSPACE=/workspace
ENV WORKSPACE=${WORKSPACE}

# ==========================================
# Dependências do sistema
# ==========================================
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xterm \
        iptables \
        ipset \
        iproute2 \
        iputils-ping \
        dnsutils \
        aggregate \
        curl \
        ca-certificates \
        gh \
        openssh-client \
        jq \
        procps \
        xdg-utils \
        xauth \
        xclip \
        xsel \
        bubblewrap \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git lfs install --system
RUN npm install -g @openai/codex@latest --include=optional \
    && codex --version

# =============================================================================
# SSH
# =============================================================================
RUN mkdir -p /home/${USERNAME}/.ssh \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh \
    && chmod 700 /home/${USERNAME}/.ssh

RUN mkdir -p /home/${USERNAME}/.vscode-server  \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.vscode-server  \
    && chmod 700 /home/${USERNAME}/.vscode-server 

COPY .ai/tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY .ai/setup-codex-any-user.sh /usr/local/sbin/setup-codex.sh
COPY .ai/tools/post-start.sh /usr/local/sbin/post-start.sh
COPY .ai/tools/open-user-shell.sh /usr/local/sbin/open-user-shell.sh

RUN chmod 755 /usr/local/sbin/post-start.sh \
            /usr/local/sbin/setup-codex.sh \
            /usr/local/sbin/open-user-shell.sh

RUN chmod +x /usr/local/sbin/post-start.sh \
            /usr/local/sbin/setup-codex.sh \
            /usr/local/sbin/open-user-shell.sh

RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "${USERNAME} ALL=(root) NOPASSWD: \
        /usr/local/sbin/setup-codex.sh, \
        /usr/local/sbin/open-user-shell.sh" \        
        > /etc/sudoers.d/${USERNAME}-dev \
    && chmod 0440 /etc/sudoers.d/${USERNAME}-dev \
    && visudo -cf /etc/sudoers.d/${USERNAME}-dev

WORKDIR ${WORKSPACE}
ENTRYPOINT ["docker-entrypoint.sh"]