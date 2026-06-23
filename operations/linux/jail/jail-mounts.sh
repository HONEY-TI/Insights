#!/usr/bin/env bash
set -euo pipefail

readonly USER_ORG="alexf"
readonly USER_DEST="alex"
readonly GROUP_DEFAULT="grp-alex"

# =========================================================
# 🧱 MOUNTS FIXOS
# =========================================================
declare -a MOUNTS=(
    "/home/$USER_ORG/.workspace:/home/$USER_DEST/.workspace:$USER_DEST"
    "/home/$USER_ORG/Documentos:/home/$USER_DEST/Documentos:$USER_DEST"
    "/home/$USER_ORG/.virtual-vms:/home/$USER_DEST/.virtual-vms:$USER_DEST"

    "/home/shared-documents:/home/jail/Documentos:root:jailusers"
    "/home/$USER_DEST/.workspace:/home/jail/workspace:root:jailusers"
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
mount_bindfs_jail() {
    local SHARED_DOCUMENTS="/home/jail/Documentos"
    local SHARED_WORKSPACE="/home/jail/workspace"

    for user in "${JAIL_USERS[@]}"; do
        local documents="/home/jail/home/$user/Documentos"
        local workspace="/home/jail/home/$user/workspace"

        chmod 2776 "$SHARED_DOCUMENTS" 2>/dev/null || true
        bindfs \
            --force-user="$user" \
            --force-group="$user" \
            "$SHARED_DOCUMENTS" \
            "$documents" || true
        chmod 2776 "$documents" 2>/dev/null || true

        chmod 2776 "$SHARED_WORKSPACE" 2>/dev/null || true
        bindfs \
            --force-user="$user" \
            --force-group="$user" \
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

mount_bindfs_jail