#!/usr/bin/env bash

# remove-user-clean.sh
#
# Uso:
#   sudo ./remove-user-clean.sh usuario
#
# Exemplo:
#   sudo ./remove-user-clean.sh usuario

set -uo pipefail

ERROS=()

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

erro() {
    ERROS+=("$*")
    echo "[ERRO] $*"
}

run() {
    "$@" >/dev/null 2>&1 || erro "$*"
}

if [[ $EUID -ne 0 ]]; then
    echo "Execute como root."
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 usuario"
    exit 1
fi


USER_NAME="$1"

log "Iniciando limpeza do usuário: $USER_NAME"


########################################
# Descobrir informações do usuário
########################################

USER_INFO=$(getent passwd "$USER_NAME" || true)

if [[ -n "$USER_INFO" ]]; then

    HOME_DIR=$(echo "$USER_INFO" | cut -d: -f6)
    USER_UID=$(echo "$USER_INFO" | cut -d: -f3)

else

    log "Usuário não existe mais no cadastro."

    HOME_DIR="/home/$USER_NAME"

    USER_UID=""

    if [[ -d "$HOME_DIR" ]]; then
        USER_UID=$(stat -c "%u" "$HOME_DIR" 2>/dev/null || true)
    fi

fi


log "Home detectada: $HOME_DIR"

if [[ -n "$USER_UID" ]]; then
    log "UID detectado: $USER_UID"
fi


########################################
# Encerrar sessões
########################################

log "Encerrando sessões..."

run loginctl terminate-user "$USER_NAME"
run loginctl kill-user "$USER_NAME"


########################################
# Encerrar processos
########################################

log "Encerrando processos..."

run pkill -TERM -u "$USER_NAME"

sleep 3

run pkill -KILL -u "$USER_NAME"


if [[ -n "$USER_UID" ]]; then
    run pkill -KILL -U "$USER_UID"
fi


########################################
# Desmontar tudo ligado a HOME
########################################

if [[ -d "$HOME_DIR" ]]; then

    log "Procurando mounts..."

    mapfile -t MOUNTS < <(
        findmnt -R -n -o TARGET "$HOME_DIR" 2>/dev/null | sort -r
    )

    for MOUNT in "${MOUNTS[@]}"; do

        [[ -z "$MOUNT" ]] && continue

        log "Desmontando: $MOUNT"

        if ! umount -lf "$MOUNT" 2>/dev/null; then
            erro "Não desmontou: $MOUNT"
        fi

    done

fi


########################################
# Remover conta se existir
########################################

if getent passwd "$USER_NAME" >/dev/null; then

    log "Removendo usuário..."

    if ! userdel "$USER_NAME"; then
        erro "Falha removendo usuário"
    fi

else

    log "Conta já removida."

fi


########################################
# Remover grupo
########################################

if getent group "$USER_NAME" >/dev/null; then

    log "Removendo grupo..."

    run groupdel "$USER_NAME"

fi


########################################
# Remover diretórios conhecidos
########################################

log "Removendo home..."

if [[ -d "$HOME_DIR" ]]; then

    rm -rf "$HOME_DIR" || erro "Falha removendo $HOME_DIR"

fi


log "Removendo runtime..."

if [[ -n "$USER_UID" ]]; then

    rm -rf "/run/user/$USER_UID" \
        || erro "Falha removendo runtime"

fi


log "Removendo emails..."

rm -rf "/var/mail/$USER_NAME" 2>/dev/null || true
rm -rf "/var/spool/mail/$USER_NAME" 2>/dev/null || true


########################################
# Remover arquivos temporários
########################################

log "Limpando temporários..."

find /tmp /var/tmp \
    -user "$USER_NAME" \
    -exec rm -rf {} + \
    2>/dev/null || true


########################################
# Procurar restos por UID
########################################

if [[ "$USER_UID" =~ ^[0-9]+$ ]]; then

    log "Procurando arquivos restantes do UID $USER_UID..."

    find / \
        -xdev \
        -uid "$USER_UID" \
        -print \
        2>/dev/null

fi


########################################
# Resultado
########################################

echo
echo "================================"
echo " LIMPEZA FINALIZADA"
echo "================================"

if [[ ${#ERROS[@]} -gt 0 ]]; then

    echo
    echo "Falhas encontradas:"
    printf '%s\n' "${ERROS[@]}"

else

    echo "Nenhum erro registrado."

fi