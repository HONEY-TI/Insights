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
        iptables \
        ipset \
        iproute2 \
        iputils-ping \
        dnsutils \
        gh \
        openssh-client \
        jq \
        procps \
        xdg-utils \
        xauth \
        xclip \
        xsel \
        # sandbox         
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

COPY .ai/tools/post-start.sh /usr/local/sbin/post-start.sh
COPY .ai/tools/docker-entrypoint.sh /usr/local/sbin/docker-entrypoint.sh
COPY .ai/setup-codex-any-user.sh /usr/local/sbin/setup-codex.sh

RUN chmod 755 /usr/local/sbin/post-start.sh \
            /usr/local/sbin/docker-entrypoint.sh \
            /usr/local/sbin/setup-codex.sh

RUN chmod +x /usr/local/sbin/post-start.sh \
            /usr/local/sbin/docker-entrypoint.sh \
            /usr/local/sbin/setup-codex.sh

# =============================================================================
# GIT CONFIG
# =============================================================================
RUN mkdir -p /home/${USERNAME} && \
    printf '[user]\n    name = Alex Ribeiro de Faria\n    email = 135660435+alexribeirofaria@github.com\n' \
    > /home/${USERNAME}/.gitconfig && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.gitconfig

RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "${USERNAME} ALL=(root) NOPASSWD: \
        /usr/local/sbin/post-start.sh, \
        /usr/local/sbin/setup-codex.sh, \
        /usr/local/sbin/docker-entrypoint.sh" \
        > /etc/sudoers.d/${USERNAME}-dev \
    && chmod 0440 /etc/sudoers.d/${USERNAME}-dev \
    && visudo -cf /etc/sudoers.d/${USERNAME}-dev

# =============================================================================
# 🔄 AUTO SWITCH — ROOT ➜ node
# =============================================================================
# 📌 false = DESATIVADO | true = ATIVADO
# =============================================================================
ARG ENABLE_SWITCH_USER=true
RUN if [ "$ENABLE_SWITCH_USER" = "true" ]; then \
        echo "🔄 Configurando auto switch: root ➜ ${USERNAME}"; \
        printf '%s\n' \
            'if [ "${AUTO_SWITCHED}" != "1" ]; then' \
            '    export AUTO_SWITCHED=1' \
            '    exec su - ${USERNAME}' \
            'fi' \
            > /root/.switch_user; \
        echo "source /root/.switch_user" >> /root/.bashrc; \
        echo "source /root/.switch_user" >> /root/.bash_profile; \
        echo ". /root/.switch_user" >> /root/.profile; \
    else \
        echo "⏭️  Auto switch root ➜ ${USERNAME}: DESATIVADO"; \
    fi

WORKDIR ${WORKSPACE}
ENTRYPOINT ["docker-entrypoint.sh"]