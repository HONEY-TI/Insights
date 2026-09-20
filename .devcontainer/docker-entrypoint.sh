#!/bin/bash
set -e

readonly USER=node
readonly HOME_DIR="/home/${USER}"

# Este entrypoint precisa começar como root.
if [ "$(id -u)" -ne 0 ]; then
    echo "[entrypoint] ERRO: o entrypoint precisa ser executado como root."
    echo "[entrypoint] UID atual: $(id -u)"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Descobrir UID/GID do bind mount
# ─────────────────────────────────────────────────────────────────────────────

HOST_UID=$(stat -c '%u' /workspace)
HOST_GID=$(stat -c '%g' /workspace)

CURRENT_UID=$(id -u "$USER")
CURRENT_GID=$(id -g "$USER")

echo "[entrypoint] /workspace pertence a UID:GID ${HOST_UID}:${HOST_GID}"
echo "[entrypoint] usuário '$USER' atualmente é UID:GID ${CURRENT_UID}:${CURRENT_GID}"

# ─────────────────────────────────────────────────────────────────────────────
# Ajustar GID
# ─────────────────────────────────────────────────────────────────────────────

if [ "$HOST_GID" != "$CURRENT_GID" ]; then
    echo "[entrypoint] ajustando GID de '$USER' para $HOST_GID"

    groupmod -o -g "$HOST_GID" "$USER"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Ajustar UID
# ─────────────────────────────────────────────────────────────────────────────

if [ "$HOST_UID" != "$CURRENT_UID" ]; then
    echo "[entrypoint] ajustando UID de '$USER' para $HOST_UID"

    usermod -o -u "$HOST_UID" "$USER"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Garantir HOME e VS Code Server
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p "$HOME_DIR"
mkdir -p "$HOME_DIR/.vscode-server"

chown "$HOST_UID:$HOST_GID" "$HOME_DIR"
chown -R "$HOST_UID:$HOST_GID" "$HOME_DIR/.vscode-server"

chmod u+rwx "$HOME_DIR"
chmod u+rwx "$HOME_DIR/.vscode-server"

echo "[entrypoint] node agora é UID:GID $(id -u "$USER"):$(id -g "$USER")"
echo "[entrypoint] HOME: $(stat -c '%u:%g %a %n' "$HOME_DIR")"
echo "[entrypoint] VS Code Server: $(stat -c '%u:%g %a %n' "$HOME_DIR/.vscode-server")"

# ─────────────────────────────────────────────────────────────────────────────
# Executar comando final como node
# ─────────────────────────────────────────────────────────────────────────────

exec "$@"

