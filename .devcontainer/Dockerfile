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
RUN echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh, /usr/local/bin/generate-openclaw-config.sh, /usr/local/bin/docker-entrypoint.sh" \
    > /etc/sudoers.d/node-dev \
    && chmod 0440 /etc/sudoers.d/node-dev

# ── Bash personalizado (global, para qualquer usuário) ──────────────────────
RUN cat >> /etc/bash.bashrc   <<'EOF'
export PATH="/bin:/usr/local/bin:/home/node/.local/bin:/home/node/.npm-global/bin:$PATH"

alias cls='clear'

function ls() { command eza -la --group --group-directories-first "$@"; }

alias ll='eza -lh --group --icons'
alias la='eza -lah --group'
alias lt='eza --tree --level=2 --group'

# ==========================================
# VENV + GIT BRANCH NO PROMPT
# ==========================================

function parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    [ -n "$branch" ] && printf " (%s)" "$branch"
}

PS1='$(if [ -n "$MY_VENV" ]; then printf "\[\e[1;31m\](venv)\[\e[0m\] "; fi)\[\e[1;34m\]╭─\[\e[1;36m\]\u\[\e[0m\] \[\e[1;32m\]\w\[\e[1;33m\]$(parse_git_branch)\[\e[0m\]\n\[\e[1;34m\]╰─❯ \[\e[0m\]'

EOF


USER node
RUN cp /etc/bash.bashrc /home/node/.bashrc

ARG GITHUB_TOKEN
RUN if [ -n "$GITHUB_TOKEN" ]; then \
      echo "${GITHUB_TOKEN}" | gh auth login --with-token || echo "gh auth falhou, seguindo sem autenticar"; \
    else \
      echo "GITHUB_TOKEN não fornecido, pulando gh auth login"; \
    fi

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
