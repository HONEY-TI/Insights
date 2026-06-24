#!/bin/bash

# =========================================================
# 🔐 JailKit Shared User Creator
# =========================================================
# 🔥 IMPORTANTE: Esse script possui dependência direta de remove-jail-user
#
# Uso:
# ./create-jail-user <user login>
#
# Exemplo:
# ./create-jail-user codex-user
#
# 🔥 IMPORTANTE: Para scripts administrativos compartilhados no Linux, os locais mais adequados são:
#   ✅ Local Ideal para scripts administrativos (sudo) /usr/local/sbin
#   sudo cp -r create-jail-user /usr/local/sbin/create-jail-user
#
# ⚙️ Tornar script executável
#  chmod +x create-jail-user
#
# ⚙️ Permitir execução apenas para root e grupo sudo
#   sudo chown root:sudo create-jail-user
#   sudo chmod 750 create-jail-user
#
# =========================================================

set -euo pipefail

# =========================================================
# 🔐 CONFIGURAÇÕES
# =========================================================

readonly JAIL_PATH="/home/jail"
readonly GROUP_NAME="jailusers"
readonly DEFAULT_PASSWORD="7004"

USERNAME="${1:-}"
USER_HOME="$JAIL_PATH/home/$USERNAME"

# =========================================================
# 👑 VALIDAR ROOT
# =========================================================

validate_root() {
    [[ "$EUID" -eq 0 ]] || {
        echo "❌ Execute como root."
        exit 1
    }
}

# =========================================================
# ❌ VALIDAR USUÁRIO
# =========================================================

validate_username() {
    [[ -n "$USERNAME" ]] || {
        echo "❌ Informe o usuário."
        echo "Uso: sudo create-jail-user <usuario>"
        exit 1
    }
}

# =========================================================
# 📦 GARANTIR DEPENDÊNCIAS
# =========================================================

ensure_group_exists() {
    getent group "$GROUP_NAME" >/dev/null || groupadd "$GROUP_NAME"
}

# =========================================================
# 🗑️ REMOVER USUÁRIO EXISTENTE
# =========================================================

remove_existing_user() {
    if id "$USERNAME" &>/dev/null; then
        echo "⚠️ Usuário já existe."
        read -rp "Remover e recriar? (s/N): " CONFIRM

        if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
            remove-jail-user "$USERNAME" || true
        else
            exit 1
        fi
    fi
}

# =========================================================
# 👤 CRIAR USUÁRIO
# =========================================================

create_user() {
    local full_name="$(echo "${USERNAME%%-*}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

    useradd \
        -m \
        -c "$full_name" \
        -d "/home/$USERNAME" \
        -s /usr/bin/bash \
        -U \
        -G "$GROUP_NAME" \
        "$USERNAME"
    
    echo "$USERNAME:$DEFAULT_PASSWORD" | chpasswd >/dev/null 2>&1 
}

# =========================================================
# 🔒 CONFIGURAR JAILKIT
# =========================================================

configure_jailkit() {

    jk_jailuser \
        -m \
        -j "$JAIL_PATH" \
        "$USERNAME"
}

# =========================================================
# 🏠 CONFIGURAR HOME DENTRO DA JAIL
# =========================================================

configure_home() {

    mkdir -p \
        "$USER_HOME/.config" \
        "$USER_HOME/.cache" \
        "$USER_HOME/.local/share" 

    cat > "$USER_HOME/.profile" <<EOF
export DISPLAY=:0
export XAUTHORITY=\$HOME/.Xauthority

[ -f ~/.bashrc ] && . ~/.bashrc
EOF

    cat > "$USER_HOME/.bashrc" <<EOF
export PATH=/usr/local/bin:/usr/bin:/bin

alias ll='ls -lah'
PS1='\[\e[0;32m\][\[\e[1;34m\]\u\[\e[0m\]:\[\e[1;36m\]\w\[\e[0m\]\[\e[1;33m\]$\[\e[0m\]\[\e[0;32m\]]\[\e[0m\]\$ '

EOF

    touch \
        "$USER_HOME/.bash_logout" \
        "$USER_HOME/.Xauthority"

    chown -R "$USERNAME:$GROUP_NAME" "$JAIL_PATH/home/$USERNAME"

    chmod 750 "$JAIL_PATH/home/$USERNAME"
    
    chmod 700 \
        "$USER_HOME/.cache" \
        "$USER_HOME/.config" \
        "$USER_HOME/.local"

    chmod 600 "$USER_HOME/.Xauthority"
}

# =========================================================
# 📂 SHARED FOLDERS
# =========================================================

create_shared_folder() {

    local src="$1"
    local dst="$2"

    mkdir -p "$src"
    mkdir -p "$dst"
    chmod 2776 "$src" 2>/dev/null || true

    if ! mountpoint -q "$dst"; then
        bindfs \
        --force-user="$USERNAME" \
        --force-group="$USERNAME" \
        "$src" \
        "$dst"
    fi
    chmod 2776 "$dst"
}

# =========================================================
# ➕ Adicionar usuário a lista de persistencia de mount 
# =========================================================
add_jail_user_to_list_persist_bind_mount() {
    local file="/home/jail/etc/jail-users.list"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    # evita duplicado
    if ! grep -qx "$USERNAME" "$file"; then
        echo "$USERNAME" >> "$file"
    fi
}

# =========================================================
# ➕ Configurar git gh auth 
# =========================================================

configure_gh_auth_manual() {

    local gh_dir="$USER_HOME/.config/gh"

    mkdir -p "$gh_dir"

    cat > "$gh_dir/hosts.yml" <<EOF
github.com:
    user: $USERNAME
    oauth_token: PLACE_YOUR_TOKEN_HERE
    git_protocol: https
EOF

    chown -R "$USERNAME:$GROUP_NAME" "$gh_dir"
    chmod 770 "$USER_HOME/.config"
    chmod 770 "$gh_dir"
    chmod 660 "$gh_dir/hosts.yml"
}



# =========================================================
# 🖥️ X11
# =========================================================

configure_x11() {
    command -v xhost >/dev/null 2>&1 && \
        xhost +SI:localuser:"$USERNAME" >/dev/null 2>&1 || true
}

# =========================================================
# 🚀 EXECUÇÃO
# =========================================================

main() {

    validate_root
    validate_username
    ensure_group_exists
    remove_existing_user
    create_user
    configure_gh_auth_manual
    configure_jailkit
    configure_home
    create_shared_folder "$JAIL_PATH/Documentos" "$USER_HOME/Documentos"
    create_shared_folder "$JAIL_PATH/workspace" "$USER_HOME/workspace"
    add_jail_user_to_list_persist_bind_mount        
    configure_x11
    usermod -aG docker "$USERNAME"
    usermod -s /bin/bash "$USERNAME"

    echo ""
    echo "======================================"
    echo "✅ Usuário criado com sucesso"
    echo "======================================"
    echo "👤 Usuário : $USERNAME"
    echo "🏠 Jail    : $JAIL_PATH"
    echo ""
}

main "$@"