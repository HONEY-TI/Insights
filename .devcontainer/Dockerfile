FROM node:22-bookworm-slim
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        iptables \
        ipset \
        iproute2 \
        iputils-ping \
        dnsutils \
        jq \
        aggregate \
        curl \
        ca-certificates \
        procps \
        git \
        gh \
        openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g npm@12.0.2 \
    && npm install -g @openai/codex

# ── eza (ls moderno) ────────────────────────────────────────────────────────
ARG EZA_VERSION=0.23.4

RUN curl -fsSL \
        "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz" \
        | tar -xzf - -C /usr/local/bin \
    && chmod +x /usr/local/bin/eza

# =============================================================================
# SSH
# =============================================================================
RUN mkdir -p /home/node/.ssh \
    && chown -R node:node /home/node/.ssh \
    && chmod 700 /home/node/.ssh

# ── Firewall ────────────────────────────────────────────────────────────────
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh

COPY setup-codex.sh /usr/local/bin/setup-codex.sh
RUN chmod +x /usr/local/bin/setup-codex.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 775 /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN mkdir -p /home/node/.npm-global \
    && npm config set prefix /home/node/.npm-global
RUN npm install -g @gitlawb/openclaude@latest    

RUN mkdir -p /home/node && \
    printf '[user]\n    name = Alex Ribeiro de Faria\n    email = 135660435+alexribeirofaria@github.com\n' \
    > /home/node/.gitconfig && \
    chown node:node /home/node/.gitconfig

RUN echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh, /usr/local/bin/setup-codex.sh, /usr/local/bin/docker-entrypoint.sh" \
    > /etc/sudoers.d/node-dev \
    && chmod 0440 /etc/sudoers.d/node-dev

# ── Bash personalizado (global, para qualquer usuário) ──────────────────────
RUN cat >> /etc/bash.bashrc   <<'EOF'
export PATH="/bin:/usr/local/bin:/home/node/.local/bin:/home/node/.npm-global/bin:$PATH"

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
        --color=always \
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
        --color=always \
        "$dir"
}
# ==========================================
# VENV + GIT BRANCH NO PROMPT
# ==========================================

parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)

    [ -n "$branch" ] && printf " (%s)" "$branch"
}

set_venv_prompt() {

    local venv_prompt=""

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        venv_prompt='\[\e[1;31m\](venv)\[\e[0m\] '
    fi

    PS1='\[\e[1;32m\]┌──\[\e[0m\] '"${venv_prompt}"\
'\[\e[0;37m\](\[\e[1;34m\]\u\[\e[0;37m\]㉿\[\e[1;32m\]\h\[\e[0;37m\])\[\e[0m\]-'\
'\[\e[0;37m\][\w\[\e[1;33m\]$(parse_git_branch)\[\e[0;37m\]]\[\e[0m\]'\
'\n'\
'\[\e[1;32m\]└─\[\e[0m\]\$ '
}

activate_venv() {
    local venv="${1:-/home/jail/opt/venv}"

    if [ ! -f "$venv/bin/activate" ]; then
        echo "Erro: virtualenv não encontrado em: $venv"
        return 1
    fi

    export VIRTUAL_ENV_DISABLE_PROMPT=1
    source "$venv/bin/activate"
    set_venv_prompt
}

set_venv_prompt
EOF

RUN cp /etc/bash.bashrc /home/node/.bashrc

ARG GITHUB_TOKEN
RUN if [ -n "$GITHUB_TOKEN" ]; then \
      echo "${GITHUB_TOKEN}" | gh auth login --with-token || echo "gh auth falhou, seguindo sem autenticar"; \
    else \
      echo "GITHUB_TOKEN não fornecido, pulando gh auth login"; \
    fi


# =============================================================================
# 🔄 AUTO SWITCH — ROOT ➜ RSTUDIO
# =============================================================================
# 📌 false = DESATIVADO | true = ATIVADO
# =============================================================================

ARG ENABLE_SWITCH_USER=true

RUN if [ "$ENABLE_SWITCH_USER" = "true" ]; then \
        echo "🔄 Configurando auto switch: root ➜ node"; \
        printf '%s\n' \
            'if [ "${AUTO_SWITCHED}" != "1" ]; then' \
            '    export AUTO_SWITCHED=1' \
            '    exec su - node' \
            'fi' \
            > /root/.switch_user; \
        echo "source /root/.switch_user" >> /root/.bashrc; \
        echo "source /root/.switch_user" >> /root/.bash_profile; \
        echo ". /root/.switch_user" >> /root/.profile; \
    else \
        echo "⏭️  Auto switch root ➜ node: DESATIVADO"; \
    fi


WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
