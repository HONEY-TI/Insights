#!/usr/bin/env bash

set -euo pipefail

USER_ORG="sadmin"
USER_JAIL="jail"

JAIL_USERS_FILE="/home/${USER_JAIL}/etc/jail-users.list"
DEFAULT_GROUP="jailusers"

SOURCE_WORKSPACE="/home/${USER_ORG}/workspace"
TARGET_WORKSPACE="/home/${USER_JAIL}/workspace"

SOURCE_DOCUMENTS="/home/shared-documents"
TARGET_DOCUMENTS="/home/${USER_JAIL}/Documentos"

SOURCE_WORKSPACE_JAIL="/home/${USER_JAIL}/workspace"
SOURCE_DOCUMENTS_JAIL="/home/${USER_JAIL}/Documentos"

mount_bindfs() {
    local source="$1"
    local target="$2"
    local force_user="${3:-$USER_ORG}"
    local force_group="${4:-$DEFAULT_GROUP}"

    if [ ! -d "$source" ]; then
        echo "ERRO: origem não existe: $source"
        return 1
    fi

    mkdir -p "$target"

    if ! mountpoint -q "$target"; then
        echo "Montando:"
        echo "  Origem : $source"
        echo "  Destino: $target"
        echo "  Usuario: $force_user  Grupo: $force_group"

        bindfs \
            --force-user="$force_user" \
            --force-group="$force_group" \
            "$source" \
            "$target"
    else
        echo "Já montado: $target"
    fi
}

# Mounts fixos (sempre com USER_ORG)
mount_bindfs "$SOURCE_WORKSPACE" "$TARGET_WORKSPACE" 
mount_bindfs "$SOURCE_DOCUMENTS" "$TARGET_DOCUMENTS"

# Mounts dinâmicos por usuário dentro da jaula
if [ ! -f "$JAIL_USERS_FILE" ]; then
    echo "ERRO: lista de usuários não encontrada: $JAIL_USERS_FILE"
    exit 1
fi

while IFS= read -r USER_DEST_JAIL || [ -n "$USER_DEST_JAIL" ]; do
    [ -z "$USER_DEST_JAIL" ] && continue
    [[ "$USER_DEST_JAIL" =~ ^# ]] && continue

    TARGET_WORKSPACE_JAIL="/home/${USER_JAIL}/home/${USER_DEST_JAIL}/workspace" 
    TARGET_DOCUMENTS_JAIL="/home/${USER_JAIL}/home/${USER_DEST_JAIL}/Documentos" 

    echo "===== Processando usuário jail: $USER_DEST_JAIL ====="

    mount_bindfs "$SOURCE_WORKSPACE_JAIL" "$TARGET_WORKSPACE_JAIL" "$USER_DEST_JAIL"
    mount_bindfs "$SOURCE_DOCUMENTS_JAIL" "$TARGET_DOCUMENTS_JAIL" "$USER_DEST_JAIL"

done < "$JAIL_USERS_FILE"

echo "BindFS mounts concluídos."