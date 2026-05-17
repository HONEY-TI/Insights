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
readonly DEFAULT_PASSWORD="toor"

USERNAME="${1:-}"
USER_HOME="$JAIL_PATH/home/$USERNAME"

# =========================================================
# 👑 OWNER (DERIVADO DO SUDO USER)
# =========================================================

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    OWNER="$SUDO_USER"
else
    echo "❌ Execute via sudo (SUDO_USER não encontrado)."
    exit 1
fi

# =========================================================
# 📦 CONFIGURAÇÕES
# =========================================================
readonly SHARED_DOCUMENTS="$JAIL_PATH/documentos"
readonly SHARED_WORKSPACE="$JAIL_PATH/workspace"
readonly SHARED_VSCODE="$JAIL_PATH/.vscode"
readonly SHARED_ANTIGRAVITY="$JAIL_PATH/.antigravity"

# =========================================================
# ❌ VALIDAR USUÁRIO
# =========================================================

validate_username() {
    if [[ -z "$USERNAME" ]]; then
        echo "❌ Informe o usuário."
        echo "Uso: sudo create-jail-user <usuario>"
        exit 1
    fi
}

# =========================================================
# 👑 VALIDAR ROOT
# =========================================================

validate_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "❌ Execute como root."
        exit 1
    fi
}

# =========================================================
# 👥 GARANTIR GRUPO
# =========================================================

ensure_group_exists() {
    if ! getent group "$GROUP_NAME" >/dev/null; then
        groupadd "$GROUP_NAME"
    fi
}

# =========================================================
# 🗑️ REMOVER USUÁRIO EXISTENTE
# =========================================================

remove_existing_user() {
    if id "$USERNAME" &>/dev/null; then
        echo "⚠️ Usuário já existe."
        read -rp "Remover e recriar? (s/N): " CONFIRM

        if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
            remove-jail-user "$USERNAME"
        else
            exit 1
        fi
    fi
}

# =========================================================
# 👤 CRIAR USUÁRIO
# =========================================================

create_user() {
    FULL_NAME="$(echo "${USERNAME%%-*}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

    useradd \
        -m \
        -c "$FULL_NAME" \
        -d "/home/$USERNAME" \
        -s /usr/sbin/jk_chrootsh \
        -U \
        -G "$GROUP_NAME" \
        "$USERNAME"
    
    echo "$USERNAME:$DEFAULT_PASSWORD" | chpasswd
}

# =========================================================
# 🔐 CONFIGURAR JAILKIT
# =========================================================

configure_jailkit() {

    jk_jailuser \
        -m \
        -j "$JAIL_PATH" \
        "$USERNAME"
}

# =========================================================
# 🏠 CONFIGURAR HOME (JAIL REAL)
# =========================================================

configure_home() {

    mkdir -p \
        "$JAIL_PATH/home/$USERNAME" \
        "$USER_HOME/.config" \
        "$USER_HOME/.cache" \
        "$USER_HOME/.local/share" \
        "$USER_HOME/.vscode" \
        "$USER_HOME/.antigravity" \
        "$USER_HOME/Documentos" \
        "$USER_HOME/workspace" \
        "$USER_HOME/Downloads"

    cat > "$USER_HOME/.profile" <<EOF
export DISPLAY=:0
export XAUTHORITY=\$HOME/.Xauthority

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

    cat > "$USER_HOME/.bashrc" <<EOF
export DISPLAY=:0
export XAUTHORITY=\$HOME/.Xauthority

export PATH=/usr/local/bin:/usr/bin:/bin

alias ll='ls -lah'
EOF

    touch \
        "$USER_HOME/.bash_logout" \
        "$USER_HOME/.Xauthority"

    chown -R "$USERNAME:$GROUP_NAME" "$JAIL_PATH/home/$USERNAME"

    chmod 755 "$JAIL_PATH/home"
    chmod 750 "$JAIL_PATH/home/$USERNAME"

    find "$JAIL_PATH/home/$USERNAME" -type d -exec chmod 755 {} \;
    find "$JAIL_PATH/home/$USERNAME" -type f -exec chmod 644 {} \;

    chmod 700 \
        "$USER_HOME/.cache" \
        "$USER_HOME/.config" \
        "$USER_HOME/.local"

    chmod 600 "$USER_HOME/.Xauthority"
}

# =========================================================
# 📂 CRIAR PASTA COMPARTILHADA
# =========================================================

create_shared_folder() {

    local source_folder="$1"
    local target_folder="$2"

    mkdir -p "$source_folder"
    mkdir -p "$target_folder"

    if mountpoint -q "$target_folder"; then
        umount -l "$target_folder"
    fi

    mount --bind "$source_folder" "$target_folder"
}


# =========================================================
# 🖥️ LIBERAR X11
# =========================================================

configure_x11() {
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
    configure_jailkit
    configure_home

    create_shared_folder "$SHARED_DOCUMENTS" "$USER_HOME/Documentos"
    create_shared_folder "$SHARED_WORKSPACE" "$USER_HOME/workspace"
    create_shared_folder "$SHARED_VSCODE" "$USER_HOME/.vscode"
    create_shared_folder "$SHARED_ANTIGRAVITY" "$USER_HOME/.antigravity"

    configure_x11    
    usermod -s /bin/bash "$USERNAME"
    

    echo ""
    echo "======================================"
    echo "✅ Usuário criado com sucesso"
    echo "======================================"
    echo "👤 Usuário : $USERNAME"
    echo "🏠 Jail    : $JAIL_PATH"
    echo ""
}

main