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
# 🗑️ JailKit Shared User Remover (FIXED)
# =========================================================

readonly JAIL_PATH="/home/jail"
USERNAME="${1:-}"

# =========================================================
# 🔐 VALIDAR ROOT
# =========================================================
validate_root() {
    [[ "${EUID:-0}" -eq 0 ]] || {
        echo "❌ Execute com sudo/root."
        exit 1
    }
}

# =========================================================
# 👤 VALIDAR USERNAME
# =========================================================
validate_username() {
    [[ -n "$USERNAME" ]] || {
        echo "❌ Informe o usuário."
        echo "Uso: sudo remove-jail-user <username>"
        exit 1
    }
}

# =========================================================
# 🛑 FINALIZAR PROCESSOS
# =========================================================
kill_user_processes() {
    echo "🛑 Encerrando processos..."
    pkill -u "$USERNAME" 2>/dev/null || true
}

# =========================================================
# 🔓 DESMONTAR BIND MOUNTS
# =========================================================
safe_unmount() {

    local target="$1"

    # evita erro se não existe
    [[ -e "$target" ]] || return 0

    # verifica mount real
    if mountpoint -q "$target"; then

        echo "🔓 Desmontando bindfs: $target"

        umount "$target" 2>/dev/null || \
        umount -l "$target" 2>/dev/null || \
        echo "⚠️ Falha ao desmontar $target (talvez busy)"
    fi
}

unmount_shared_folders() {

    echo "🔓 Procurando mounts bindfs do usuário: $USERNAME"

    # pega todos os mounts bindfs
    mount | grep bindfs | awk '{print $3}' | while read -r mnt; do

        # só desmonta os que pertencem ao jail do usuário
        if echo "$mnt" | grep -q "$USERNAME"; then
            safe_unmount "$mnt"
        fi

    done
}

# =========================================================
# 🧹 REMOVER HOME DA JAIL
# =========================================================
remove_jail_home() {
    local jail_home="$JAIL_PATH/home/$USERNAME"

    echo "🧹 Removendo home da jail..."

    rm -rf "$JAIL_PATH/home/$USERNAME"
}

# =========================================================
# 🧹 REMOVER ENTRADA DA JAIL (passwd/group)
# =========================================================
remove_jail_entries() {

    echo "🧹 Removendo entradas da jail..."

    sed -i "/^$USERNAME:/d" "$JAIL_PATH/etc/passwd" 2>/dev/null || true
    sed -i "/^$USERNAME:/d" "$JAIL_PATH/etc/group" 2>/dev/null || true
}

# =========================================================
# 🧹 REMOVER CONFIG JK_CHROOTSH
# =========================================================
remove_jk_chrootsh_config() {

    local config="/etc/jailkit/jk_chrootsh.ini"

    [[ -f "$config" ]] || return 0

    echo "🧹 Limpando jk_chrootsh..."

    awk -v user="[/home/$USERNAME]" '
    $0 == user { skip=1; next }
    /^\[/ { skip=0 }
    !skip { print }
    ' "$config" > "${config}.tmp" && mv "${config}.tmp" "$config"
}

# =========================================================
# 🗑️ REMOVER USUÁRIO DO SISTEMA
# =========================================================
remove_system_user() {

    echo "🗑️ Removendo usuário do sistema..."

    userdel -r "$USERNAME" 2>/dev/null || userdel "$USERNAME" 2>/dev/null || true
}

# =========================================================
# 👥 REMOVER GRUPOS
# =========================================================
remove_groups() {

    echo "🧹 Removendo grupos..."

    if getent group docker >/dev/null 2>&1; then
        gpasswd -d "$USERNAME" docker 2>/dev/null || true
    fi

    if getent group "$USERNAME" >/dev/null 2>&1; then
        groupdel "$USERNAME" 2>/dev/null || true
    fi
}

# =========================================================
# ❌ Remover usuário
# =========================================================
remove_jail_user_from_list_bind_mount() {
    local file="/home/jail/etc/jail-users.list"

    [[ -f "$file" ]] || return 0

    sed -i "\|^${USERNAME}$|d" "$file"
}

# =========================================================
# 🧹 LIMPEZA FINAL JAILKIT
# =========================================================
cleanup_jailkit() {

    echo "🧹 Limpeza final da jail..."

    rm -rf "$JAIL_PATH/home/$USERNAME" 2>/dev/null || true
}

# =========================================================
# 🚀 EXECUÇÃO
# =========================================================
main() {

    validate_root
    validate_username

    kill_user_processes
    unmount_shared_folders
    
    remove_system_user
    remove_jail_home
    remove_jail_entries
    remove_jail_user_from_list_bind_mount
    remove_groups
    remove_jk_chrootsh_config   
    
    cleanup_jailkit

    echo ""
    echo "========================================="
    echo "✅ Usuário removido com sucesso"
    echo "========================================="
    echo "👤 Usuário : $USERNAME"
    echo "🗑️ Jail    : $JAIL_PATH"
    echo "========================================="
    echo ""
}

main "$@"