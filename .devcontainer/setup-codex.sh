#!/bin/bash
set -e

readonly PROJECT_WORKSPACE=/workspace

cd -- "$PROJECT_WORKSPACE"

exec su - node -c '
    set -e

    echo "[codex] verificando autenticação..."

    if ! codex login status >/dev/null 2>&1; then
        echo "[codex] autenticação necessária."
        echo "[codex] iniciando Device Code..."
        codex login --device-auth
    fi

    echo "[codex] validando configuração..."
    codex --strict-config
'