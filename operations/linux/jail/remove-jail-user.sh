#!/bin/bash

# =========================================================
# 🗑️ JailKit Shared User Remover 
# =========================================================
#
# Uso:
# ./remove-jail-user <user login>
#
# Exemplo:
# ./remove-jail-user codex-user
#
# 🔥 IMPORTANTE: Para scripts administrativos compartilhados no Linux, os locais mais adequados são:
#   ✅ Local Ideal para scripts administrativos (sudo) /usr/local/sbin
#   sudo cp -r remove-jail-user /usr/local/sbin/remove-jail-user
#
# ⚙️ Tornar script executável
#  chmod +x remove-jail-user
#
# ⚙️ Permitir execução apenas para root e grupo sudo
#   sudo chown root:sudo remove-jail-user
#   sudo chmod 750 remove-jail-user
# =========================================================

set -euo pipefail

# =========================================================
# 📦 CONFIGURAÇÕES
# =========================================================

readonly JAIL_PATH="/
jail"

USERNAME="${1:-}"

readonly USER_HOME="$JAIL_PATH/home/$USERNAME"

# =========================================================
# 👑 VALIDAR ROOT
# =========================================================

validate_root() {
    if [[ "${EUID:-0}" -ne 0 ]]; then
        echo "❌ Execute com sudo."
        exit 1
    fi
}

# =========================================================
# 👤 VALIDAR PARÂMETRO
# =========================================================

validate_username() {
    if [[ -z "$USERNAME" ]]; then
        echo "❌ Informe o nome do usuário."
        echo "Uso: sudo remove-jail-user.sh <username>"
        exit 1
    fi
}

# =========================================================
# 🔍 VALIDAR USUÁRIO
# =========================================================

validate_user_exists() {
    if ! id "$USERNAME" &>/dev/null; then
        echo "❌ Usuário '$USERNAME' não existe."
        exit 1
    fi
}

# =========================================================
# 🛑 ENCERRAR PROCESSOS
# =========================================================

kill_user_processes() {
    echo "🛑 Encerrando processos do usuário..."
    pkill -u "$USERNAME" || true
}

# =========================================================
# 🔓 DESMONTAR SAFE (IMPORTANTE)
# =========================================================

safe_unmount() {
    local target="$1"

    if mountpoint -q "$target"; then
        echo "🔓 Desmontando: $target"
        umount "$target" 2>/dev/null || umount -l "$target" || true
    fi
}

# =========================================================
# 🔓 DESMONTAR BIND MOUNTS (JAILKIT FIX)
# =========================================================

unmount_shared_folders() {



    local doc="$USER_HOME/Documentos"
    local ws="$USER_HOME/workspace"
    local vscode="$USER_HOME/.vscode"
    local antigravity="$USER_HOME/.antigravity"

    safe_unmount "$doc"
    safe_unmount "$ws"
    safe_unmount "$vscode"
    safe_unmount "$antigravity"
}

# =========================================================
# 🧹 REMOVER HOME DA JAIL 
# =========================================================

remove_jail_home() {

    local jail_home="$JAIL_PATH/home/$USERNAME"

    if [[ -d "$jail_home" ]]; then
        echo "🧹 Removendo home da jail: $jail_home"
        rm -rf "$jail_home"
    fi
}

# =========================================================
# 🗑️ REMOVER USUÁRIO DO SISTEMA 
# =========================================================

remove_system_user() {

    echo "🗑️ Removendo usuário do sistema..."

    userdel -r "$USERNAME" 2>/dev/null || userdel "$USERNAME" || true
}

# =========================================================
# 👥 REMOVER GRUPO DO USUÁRIO (SE EXISTIR)
# =========================================================

remove_user_group() {

    if getent group "$USERNAME" >/dev/null 2>&1; then
        echo "🧹 Removendo grupo '$USERNAME'..."
        groupdel "$USERNAME" || true
    fi
}

# =========================================================
# 🧹 LIMPEZA EXTRA JAILKIT (IMPORTANTE)
# =========================================================

cleanup_jailkit_references() {

    echo "🧹 Limpando referências no jail..."

    rm -rf "$JAIL_PATH/home/$USERNAME" 2>/dev/null || true

    find "$JAIL_PATH" -name "*$USERNAME*" -type d -exec rm -rf {} + 2>/dev/null || true
}

# =========================================================
# 🚀 EXECUÇÃO
# =========================================================

main() {

    validate_root
    validate_username
    validate_user_exists

    kill_user_processes

    unmount_shared_folders

    remove_jail_home

    remove_system_user

    remove_user_group

    cleanup_jailkit_references

    echo ""
    echo "========================================="
    echo "✅ Usuário removido com sucesso"
    echo "========================================="
    echo ""
    echo "👤 Usuário : $USERNAME"
    echo "🗑️ Jail    : $JAIL_PATH"
    echo ""
}

main
