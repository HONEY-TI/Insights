FROM node:24.21.0-bookworm-slim
USER root
ARG USERNAME=node
ENV EXPECTED_USER=${USERNAME}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        sudo \
        iptables \
        ipset \
        iproute2 \
        iputils-ping \
        dnsutils \
        aggregate \
        curl \
        ca-certificates \
        procps \
        git \
        gh \
        openssh-client \
        xdg-utils \
        xauth \
        xclip \
        xsel \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV BROWSER=echo

RUN npm install -g npm@12.0.2 \
    && npm install -g @openai/codex@latest --include=optional && codex --version

# ── eza (ls moderno) ────────────────────────────────────────────────────────
ARG EZA_VERSION=0.23.4
RUN curl -fsSL \
        "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz" \
        | tar -xzf - -C /usr/local/bin \
    && chmod +x /usr/local/bin/eza

# =============================================================================
# SSH
# =============================================================================
RUN mkdir -p /home/${USERNAME}/.ssh \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh \
    && chmod 700 /home/${USERNAME}/.ssh

RUN mkdir -p /home/${USERNAME}/.vscode-server  \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.vscode-server  \
    && chmod 700 /home/${USERNAME}/.vscode-server 

COPY .devcontainer/docker-entrypoint.sh /usr/local/sbin/docker-entrypoint.sh
RUN chmod 775 /usr/local/sbin/docker-entrypoint.sh
RUN chmod +x /usr/local/sbin/docker-entrypoint.sh

COPY .devcontainer/post-start.sh /usr/local/sbin/post-start.sh
RUN chmod +x /usr/local/sbin/post-start.sh

COPY .ai/setup-codex.sh /usr/local/sbin/setup-codex.sh 
RUN chmod 775 /usr/local/sbin/setup-codex.sh
RUN chmod +x /usr/local/sbin/setup-codex.sh

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

# ── Bash personalizado (global, para qualquer usuário) ──────────────────────
RUN cat >> /etc/bash.bashrc   <<'EOF'
export PATH="$HOME/.local/bin:/usr/local/sbin:$PATH"

# =========================================================
# ALIASES
# =========================================================
alias cls='clear'
alias ll='eza -l -h --group --group-directories-first'
alias la='eza -la -hs --group --group-directories-first'
alias lt='eza --tree --level=2 --group --group-directories-first'


function ls() {
    command eza \
        -la \
        -h \
        --group \
        --group-directories-first \
        --color=auto \
        "$@"
}

function lsh() {
    local dir="${1:-.}"

    command eza \
        -la \
        -h \
        --group \
        --group-directories-first \
        --sort=size \
        --color=auto \
        "$dir"
}

# ==========================================
# GIT BRANCH NO PROMPT
# ==========================================

parse_git_branch() {
    local branch
    local git_dir

    branch=$(git branch --show-current 2>/dev/null)

    if [ -n "$branch" ]; then
        printf " (%s)" "$branch"
        return
    fi

    git_dir=$(git rev-parse --git-dir 2>/dev/null)

    if [ -n "$git_dir" ]; then
        branch=$(git -C "$(git rev-parse --show-toplevel 2>/dev/null)" \
            branch --show-current 2>/dev/null)

        [ -n "$branch" ] && printf " (%s)" "$branch"
    fi
}

set_git_prompt() {
    PS1='\[\e[1;32m\]┌──\[\e[0m\] '\
'\[\e[0;37m\](\[\e[1;34m\]\u\[\e[0;37m\]㉿\[\e[1;32m\]\h\[\e[0;37m\])\[\e[0m\]-'\
'\[\e[0;37m\][\w\[\e[1;33m\]$(parse_git_branch)\[\e[0;37m\]]\[\e[0m\]'\
'\n'\
'\[\e[1;32m\]└─\[\e[0m\]\$ '
}

set_git_prompt
EOF

RUN cp -r /etc/bash.bashrc /home/${USERNAME}/.bashrc \
    && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

# =============================================================================
# GITHUB SET 
# ============================================================================
ARG GITHUB_TOKEN
RUN if [ -n "$GITHUB_TOKEN" ]; then \
      echo "${GITHUB_TOKEN}" | gh auth login --with-token || echo "gh auth falhou, seguindo sem autenticar"; \
    else \
      echo "GITHUB_TOKEN não fornecido, pulando gh auth login"; \
    fi

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

WORKDIR /workspace
ENTRYPOINT ["docker-entrypoint.sh"]