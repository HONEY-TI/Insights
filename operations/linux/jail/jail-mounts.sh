#!/usr/bin/env bash
set -euo pipefail

readonly USER_ORG="alexf"
readonly USER_DEST="alex"
readonly GROUP_DEFAULT="grp-alex"

# =========================================================
# 🧱 MOUNTS FIXOS
# =========================================================
declare -a MOUNTS=(
    "/home/$USER_ORG/workspace:/home/jail/home/$USER_DEST/workspace:$USER_DEST:$GROUP_DEFAULT"
    "/home/$USER_ORG/Documentos:/home/jail/home/$USER_DEST/Documentos:$USER_DEST:$GROUP_DEFAULT"
    "/home/$USER_ORG/Imagens:/home/jail/home/$USER_DEST/Imagens:$USER_DEST:$GROUP_DEFAULT"
    "/home/$USER_ORG/.virtual-vms:/home/jail/home/$USER_DEST/.virtual-vms:$USER_DEST:vboxusers"
    "/home/shared-documents:/home/jail/home/$USER_DEST/Shared_Documentos:$USER_DEST:jailusers"
    
    "/home/shared-documents:/home/jail/Documentos:root:jailusers"
    "/home/$USER_ORG/.workspace:/home/jail/workspace:root:jailusers"
)

# =========================================================
# 📦 CARREGA USUÁRIOS DO JAIL
# =========================================================
JAIL_USERS=()

if [[ -f /home/jail/etc/jail-users.list ]]; then
    mapfile -t JAIL_USERS < /home/jail/etc/jail-users.list
fi

# =========================================================
# 🔗 MOUNT BASE
# =========================================================
mount_bindfs() {
    local source="$1"
    local target="$2"
    local force_user="${3:-$USER_ORG}"
    local force_group="${4:-$GROUP_DEFAULT}"

    mkdir -p "$target"

    if mountpoint -q "$target"; then
        return 0
    fi

    bindfs \
        --force-user="$force_user" \
        --force-group="$force_group" \
        "$source" \
        "$target"
}

# =========================================================
# 🔒 JAIL USERS MOUNTS
# =========================================================
mount_bindfs_jail_home_users() {
    local SHARED_DOCUMENTS="/home/jail/Documentos"
    local SHARED_WORKSPACE="/home/jail/workspace"
    local force_group="${1:-jailusers}"

    for user in "${JAIL_USERS[@]}"; do
        # Se USER_DEST for igual ao usuário atual, pula para o próximo
        [[ "$USER_DEST" == "$user" ]] && continue

        local documents="/home/jail/home/$user/Documentos"
        local workspace="/home/jail/home/$user/workspace"

        mkdir -p "$documents" "$workspace"

        chmod 2776 "$SHARED_DOCUMENTS" 2>/dev/null || true

        bindfs \
            --force-user="$user" \
            --force-group="$force_group" \
            "$SHARED_DOCUMENTS" \
            "$documents" || true

        chmod 2776 "$documents" 2>/dev/null || true

        chmod 2776 "$SHARED_WORKSPACE" 2>/dev/null || true

        bindfs \
            --force-user="$user" \
            --force-group="$force_group" \
            "$SHARED_WORKSPACE" \
            "$workspace" || true

        chmod 2776 "$workspace" 2>/dev/null || true
    done
}

# =========================================================
# 🚀 EXECUÇÃO
# =========================================================

for mount_def in "${MOUNTS[@]}"; do
    IFS=':' read -r source target user group <<< "$mount_def"

    mount_bindfs "$source" "$target" "$user" "$group"
done

mount_bindfs_jail_home_users "$GROUP_DEFAULT"
