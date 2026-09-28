#!/bin/bash

# =========================================================
# 🗑️ JailKit Shared User Remover
# =========================================================
#
# Uso:
# ./jail-remove <user login>
#
# Exemplo:
# ./jail-remove codex-user
#
# 🔥 IMPORTANTE: Para scripts administrativos compartilhados no Linux, os locais mais adequados são:
#   ✅ Local Ideal para scripts administrativos (sudo) /usr/local/sbin
#   sudo cp -r jail-remove /usr/local/sbin/jail-remove
#
# ⚙️ Tornar script executável
#  chmod +x jail-remove
#
# ⚙️ Permitir execução apenas para root e grupo sudo
#   sudo chown root:sudo jail-remove
#   sudo chmod 750 jail-remove
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
        echo "Uso: sudo jail-remove <username>"
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

    # 🔧 FIX: com "set -e -o pipefail", se "grep bindfs" não encontrar
    # nenhuma linha (exit code 1, ex: nenhum mount bindfs no momento),
    # o pipeline inteiro derrubava o script e as etapas seguintes
    # (remove_system_user, remove_jail_home, etc.) nunca rodavam —
    # o que deixava o usuário "fantasma" no sistema (existindo, mas
    # sem jail), fazendo o useradd falhar numa recriação futura.
    # A linha abaixo garante que a ausência de mounts não seja tratada
    # como erro fatal.
    local mounts
    mounts="$(mount 2>/dev/null | grep bindfs || true)"

    if [[ -z "$mounts" ]]; then
        echo "ℹ️ Nenhum mount bindfs encontrado."
        return 0
    fi

    echo "$mounts" | awk '{print $3}' | while read -r mnt; do
        if echo "$mnt" | grep -q "$USERNAME"; then
            umount -l "$mnt"
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
# 🗑️ REMOVER ARQUIVO(S) SUDOERS.D DA JAIL
# =========================================================
remove_jail_sudoers_entry() {

    local sudoers_dir="$JAIL_PATH/etc/sudoers.d"

    echo "🧹 Verificando arquivos sudoers.d do usuário..."

    [[ -d "$sudoers_dir" ]] || {
        echo "ℹ️ Diretório $sudoers_dir não existe, pulando."
        return 0
    }

    local found=0
    local f
    for f in "$sudoers_dir"/90-"$USERNAME"*; do
        [[ -e "$f" ]] || continue
        echo "🗑️ Removendo arquivo sudoers: $f"
        rm -f -- "$f"
        found=1
    done

    if [[ "$found" -eq 0 ]]; then
        echo "ℹ️ Nenhum arquivo 90-$USERNAME* encontrado em $sudoers_dir."
    fi
}

# =========================================================
# 🗑️ REMOVER USUÁRIO DO SISTEMA
# =========================================================
remove_system_user() {

    echo "🗑️ Removendo usuário do sistema..."

    userdel -r "$USERNAME" 2>/dev/null || userdel "$USERNAME" 2>/dev/null || true

    # 🔧 FIX: confirma de fato que o usuário sumiu do sistema.
    # Sem isso, uma falha silenciosa do userdel (ex: processo
    # ainda travado, home em uso) deixava o usuário "fantasma"
    # e a recriação subsequente falhava com "usuário já existe".
    if id "$USERNAME" &>/dev/null; then
        echo "❌ Falha ao remover o usuário '$USERNAME' do sistema."
        echo "   Verifique processos/sessões ativas (quem, w, ps -u $USERNAME)"
        echo "   e tente novamente."
        exit 1
    fi
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
    remove_jail_sudoers_entry
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
