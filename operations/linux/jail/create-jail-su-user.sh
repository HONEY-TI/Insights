#!/bin/bash
# =========================================================
# 🔐 JailKit Shared ADMIN User Creator (sudo SOMENTE dentro da jail)
# =========================================================
# Uso:
#   sudo ./create-jail-su-user <usuario>
#
# Exemplo:
#   sudo ./create-jail-su-user codex-admin
#
# O usuário recebe:
#   - sudo NOPASSWD SOMENTE dentro da jail
#   - SKEL de /home/jail/etc/skel
#   - zsh
#   - gum
#   - grupos necessários
#   - Documentos compartilhado
#   - workspace compartilhado
#   - configuração de monitores
#   - atalhos do VS Code
#
# O usuário NÃO recebe sudo no HOST.
# =========================================================

set -euo pipefail

# =========================================================
# CONFIGURAÇÕES
# =========================================================

readonly JAIL_PATH="/home/jail"
readonly JAIL_SKEL="$JAIL_PATH/etc/skel"
readonly DEFAULT_PASSWORD="0358"
readonly GROUP_NAME="jailusers"

# ⚠️ NÃO coloque "sudo" aqui.
# O sudo será configurado somente dentro da jail.
readonly EXTRA_HOST_GROUPS="docker,users,jailusers,gitssh"

USERNAME="${1:-}"
readonly USER_HOME="$JAIL_PATH/./home/$USERNAME"

# =========================================================
# VALIDAR ROOT
# =========================================================

validate_root() {
    [[ "$EUID" -eq 0 ]] || {
        echo "❌ Execute como root."
        echo "Uso: sudo create-jail-su-user <usuario>"
        exit 1
    }
}

# =========================================================
# VALIDAR USUÁRIO
# =========================================================

validate_username() {
    [[ -n "$USERNAME" ]] || {
        echo "❌ Informe o usuário."
        echo "Uso: sudo create-jail-su-user <usuario>"
        exit 1
    }
}

# =========================================================
# GARANTIR GRUPOS
# =========================================================

ensure_group_exists() {
    local normalized
    normalized="$(echo "$EXTRA_HOST_GROUPS" | tr -d '[:space:]')"

    getent group "$GROUP_NAME" >/dev/null || groupadd "$GROUP_NAME"

    local IFS=","
    for g in $normalized; do
        [[ -n "$g" ]] || continue
        getent group "$g" >/dev/null || {
            echo "⚠️ Grupo '$g' não existe no sistema, criando..."
            groupadd "$g"
        }
    done
}

# =========================================================
# REMOVER USUÁRIO EXISTENTE
# =========================================================

remove_existing_user() {
    if id "$USERNAME" &>/dev/null; then
        echo "⚠️ Usuário '$USERNAME' já existe."
        read -rp "Remover e recriar? (s/N): " CONFIRM

        if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
            remove-jail-user "$USERNAME" || true
        else
            echo "❌ Operação cancelada."
            exit 1
        fi
    fi
}

# =========================================================
# VALIDAR SKEL
# =========================================================

validate_skel() {
    if [[ ! -d "$JAIL_SKEL" ]]; then
        echo "❌ Diretório SKEL não existe:"
        echo "   $JAIL_SKEL"
        exit 1
    fi

    if [[ ! -r "$JAIL_SKEL" ]]; then
        echo "❌ SKEL não pode ser lido:"
        echo "   $JAIL_SKEL"
        exit 1
    fi

    echo "🧸 SKEL encontrado:"
    echo "   $JAIL_SKEL"
    echo
    echo "📦 Conteúdo do SKEL:"
    find "$JAIL_SKEL" -maxdepth 2 -print | sort
    echo
}

# =========================================================
# CRIAR USUÁRIO
# =========================================================
create_user() {
    local full_name

    full_name="$(echo "${USERNAME%%-*}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

    echo "👤 Criando usuário:"
    echo "   $USERNAME"
    echo "🏠 HOME:"
    echo "   $USER_HOME"
    echo "🧸 SKEL:"
    echo "   $JAIL_SKEL"
    echo

    useradd \
        -m \
        -k "$JAIL_SKEL" \
        -c "$full_name" \
        -d "$JAIL_PATH/./home/$USERNAME" \
        -s /usr/bin/zsh \
        -U \
        -G "$GROUP_NAME,$EXTRA_HOST_GROUPS" \
        "$USERNAME"

    echo "$USERNAME:$DEFAULT_PASSWORD" | chpasswd >/dev/null 2>&1
    
    echo "✅ Usuário criado usando SKEL."
}

# =========================================================
# CONFIGURAR JAILKIT
# =========================================================

configure_jailkit() {
    echo "🔒 Configurando JailKit..."

    jk_jailuser \
        -m \
        -j "$JAIL_PATH" \
        "$USERNAME"

    usermod \
        -d "$JAIL_PATH/home/$USERNAME" \
        -s "$JAIL_PATH/usr/bin/zsh" \
        "$USERNAME"

    echo "✅ JailKit configurado."
}

# =========================================================
# GARANTIR SUDO DENTRO DA JAIL
# =========================================================

ensure_sudo_in_jail() {
    if [[ -x "$JAIL_PATH/usr/bin/sudo" ]]; then
        echo "✅ sudo já presente na jail."
    else
        echo "🔎 Copiando sudo para dentro da jail..."

        if command -v jk_cp >/dev/null 2>&1; then
            if jk_cp -v -j "$JAIL_PATH" sudo 2>/dev/null; then
                echo "✅ sudo copiado via jk_cp."
            elif jk_cp -v -j "$JAIL_PATH" /usr/bin/sudo 2>/dev/null; then
                echo "✅ sudo copiado via caminho direto."
            else
                echo "⚠️ Não foi possível copiar sudo automaticamente."
                echo "   Verifique /etc/jailkit/jk_init.ini."
            fi
        else
            echo "⚠️ jk_cp não encontrado."
        fi
    fi

    mkdir -p "$JAIL_PATH/etc/sudoers.d"

    if [[ ! -f "$JAIL_PATH/etc/sudoers" ]]; then
        touch "$JAIL_PATH/etc/sudoers"
    fi

    chmod 440 "$JAIL_PATH/etc/sudoers"
}

# =========================================================
# GARANTIR ZSH DENTRO DA JAIL
# =========================================================

ensure_zsh_in_jail() {
    if [[ -x "$JAIL_PATH/usr/bin/zsh" ]]; then
        echo "✅ zsh já presente na jail."
        return 0
    fi

    echo "🔎 Copiando zsh para dentro da jail..."

    if command -v jk_cp >/dev/null 2>&1; then
        if jk_cp -v -j "$JAIL_PATH" zsh 2>/dev/null; then
            echo "✅ zsh copiado via jk_cp."
        elif jk_cp -v -j "$JAIL_PATH" /usr/bin/zsh 2>/dev/null; then
            echo "✅ zsh copiado via caminho direto."
        else
            echo "⚠️ Não foi possível copiar zsh automaticamente."
        fi
    else
        echo "⚠️ jk_cp não encontrado."
    fi

    if [[ ! -x "$JAIL_PATH/usr/bin/zsh" ]]; then
        echo "⚠️ zsh continua ausente dentro da jail."
    fi
}

# =========================================================
# GARANTIR GUM
# =========================================================

ensure_gum_installed() {
    if ! command -v gum >/dev/null 2>&1; then
        echo "🔎 'gum' não encontrado no host. Tentando instalar..."

        if command -v apt >/dev/null 2>&1; then
            (
                mkdir -p /etc/apt/keyrings
                curl -fsSL https://repo.charm.sh/apt/gpg.key \
                    | gpg --dearmor -o /etc/apt/keyrings/charm.gpg 2>/dev/null

                echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
                    > /etc/apt/sources.list.d/charm.list

                apt update -y >/dev/null 2>&1
                apt install -y gum >/dev/null 2>&1
            ) || true
        fi
    fi

    if command -v gum >/dev/null 2>&1; then
        echo "✅ gum disponível no host."
    else
        echo "⚠️ gum não está disponível no host."
        return 0
    fi

    if [[ -x "$JAIL_PATH/usr/bin/gum" || -x "$JAIL_PATH/usr/local/bin/gum" ]]; then
        echo "✅ gum já presente na jail."
        return 0
    fi

    echo "🔎 Copiando gum para dentro da jail..."

    if command -v jk_cp >/dev/null 2>&1; then
        if jk_cp -v -j "$JAIL_PATH" gum 2>/dev/null; then
            echo "✅ gum copiado via jk_cp."
        elif jk_cp -v -j "$JAIL_PATH" "$(command -v gum)" 2>/dev/null; then
            echo "✅ gum copiado via caminho direto."
        else
            echo "⚠️ Não foi possível copiar gum automaticamente."
        fi
    fi
}

# =========================================================
# ENDURECER /home
# =========================================================

harden_home_root() {
    local home_root="$JAIL_PATH/home"

    mkdir -p "$home_root"
    chown root:root "$home_root"
    chmod 711 "$home_root"

    echo "🔒 /home da jail protegido."
}

# =========================================================
# CONFIGURAR SUDOERS DA JAIL
# =========================================================

configure_sudoers() {
    local jail_rule="$JAIL_PATH/etc/sudoers.d/90-$USERNAME"

    mkdir -p "$JAIL_PATH/etc/sudoers.d"

    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$jail_rule"
    chmod 440 "$jail_rule"

    echo "✅ sudo NOPASSWD configurado SOMENTE dentro da jail."
}

# =========================================================
# CONFIGURAR HOME
# =========================================================

configure_home() {
    local home="$JAIL_PATH/home/$USERNAME"

    echo "🏠 Configurando HOME:"
    echo "   $home"

    mkdir -p \
        "$home/.config" \
        "$home/.cache" \
        "$home/.local/share"

    touch \
        "$home/.bash_logout" \
        "$home/.Xauthority"

    chown -R "$USERNAME:$GROUP_NAME" "$home"

    chmod 750 "$home"

    chmod 700 \
        "$home/.cache" \
        "$home/.config" \
        "$home/.local"

    chmod 600 "$home/.Xauthority"

    echo "✅ HOME configurado."
}

# =========================================================
# SHARED FOLDERS
# =========================================================

create_shared_folder() {
    local src="$1"
    local dst="$2"
    local group="${3:-jailusers}"

    mkdir -p "$src"
    mkdir -p "$dst"

    chmod 2776 "$src" 2>/dev/null || true

    if ! mountpoint -q "$dst"; then
        bindfs \
            --force-user="$USERNAME" \
            --force-group="$group" \
            "$src" \
            "$dst"
    fi

    chmod 2776 "$dst" 2>/dev/null || true

    echo "✅ Compartilhado:"
    echo "   $dst"
}

# =========================================================
# LISTA DE PERSISTÊNCIA
# =========================================================

add_jail_user_to_list_persist_bind_mount() {
    local file="/home/jail/etc/jail-users.list"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if ! grep -qx "$USERNAME" "$file"; then
        echo "$USERNAME" >> "$file"
    fi

    echo "✅ Usuário adicionado à lista de persistência."
}

# =========================================================
# MONITORES
# =========================================================

readonly MONITORS_TEMPLATE="/home/sadmin/.config/monitors.xml"

configure_monitors() {
    if [[ ! -f "$MONITORS_TEMPLATE" ]]; then
        echo "⚠️ $MONITORS_TEMPLATE não encontrado."
        return 0
    fi

    mkdir -p "$USER_HOME/.config"

    cp -f \
        "$MONITORS_TEMPLATE" \
        "$USER_HOME/.config/monitors.xml"

    chown \
        "$USERNAME:$USERNAME" \
        "$USER_HOME/.config/monitors.xml"

    chmod 644 "$USER_HOME/.config/monitors.xml"

    echo "✅ Configuração de monitores copiada."
}

# =========================================================
# ATALHOS VS CODE
# =========================================================

configure_user_vscode_shortcuts() {
    local target_dir="$USER_HOME/.config/Code/User"

    mkdir -p "$target_dir"

    cat > "$target_dir/keybindings.json" <<'EOF'
[
  {
    "key": "ctrl+'",
    "command": "workbench.action.terminal.newWithProfile"
  },
  {
    "key": "ctrl+c",
    "command": "workbench.action.terminal.copySelection",
    "when": "terminalTextSelectedInFocused || terminalFocus && terminalHasBeenCreated && terminalTextSelected || terminalFocus && terminalProcessSupported && terminalTextSelected || terminalFocus && terminalTextSelected && terminalTextSelectedInFocused || terminalHasBeenCreated && terminalTextSelected && terminalTextSelectedInFocused || terminalProcessSupported && terminalTextSelected && terminalTextSelectedInFocused"
  },
  {
    "key": "ctrl+shift+c",
    "command": "-workbench.action.terminal.copySelection",
    "when": "terminalTextSelectedInFocused || terminalFocus && terminalHasBeenCreated && terminalTextSelected || terminalFocus && terminalProcessSupported && terminalTextSelected || terminalFocus && terminalTextSelected && terminalTextSelectedInFocused || terminalHasBeenCreated && terminalTextSelected && terminalTextSelectedInFocused || terminalProcessSupported && terminalTextSelected && terminalTextSelectedInFocused"
  },
  {
    "key": "ctrl+v",
    "command": "workbench.action.terminal.paste",
    "when": "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported"
  },
  {
    "key": "ctrl+shift+v",
    "command": "-workbench.action.terminal.paste",
    "when": "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported"
  },
  {
    "key": "ctrl+shift+'",
    "command": "workbench.action.terminal.openNativeConsole",
    "when": "!isSessionsWindow && !terminalFocus"
  },
  {
    "key": "ctrl+shift+c",
    "command": "-workbench.action.terminal.openNativeConsole",
    "when": "!isSessionsWindow && !terminalFocus"
  }
]
EOF

    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/Code"

    echo "✅ Atalhos do VS Code configurados."
}

# =========================================================
# GARANTIR GH (GITHUB CLI) DENTRO DA JAIL
# =========================================================

ensure_gh_in_jail() {
    if [[ -x "$JAIL_PATH/usr/bin/gh" ]]; then
        echo "✅ gh já presente na jail."
        return 0
    fi

    if ! command -v gh >/dev/null 2>&1; then
        echo "⚠️ gh não encontrado no host, pulando."
        return 0
    fi

    echo "🔎 Copiando gh para dentro da jail..."

    if command -v jk_cp >/dev/null 2>&1; then
        if jk_cp -v -j "$JAIL_PATH" gh 2>/dev/null; then
            echo "✅ gh copiado via jk_cp."
        elif jk_cp -v -j "$JAIL_PATH" "$(command -v gh)" 2>/dev/null; then
            echo "✅ gh copiado via caminho direto."
        else
            echo "⚠️ Não foi possível copiar gh automaticamente."
        fi
    else
        echo "⚠️ jk_cp não encontrado."
    fi
}

# =========================================================
# AUTENTICAR GH DENTRO DA JAIL (opcional, via arquivo de token)
# =========================================================
# O token NUNCA fica no código nem em variável de ambiente.
# Ele é lido de um arquivo protegido no host:
#
#   /etc/jailkit/github_token
#
# Criação (uma única vez, feita manualmente):
#
#   sudo install -m 600 -o root -g root /dev/null /etc/jailkit/github_token
#   sudo nano /etc/jailkit/github_token   # cole só o token, sem espaços/quebras extras
#
# =========================================================
readonly GITHUB_TOKEN_FILE="$JAIL_PATH/etc/jailkit/github_token" 
configure_gh_auth() {

    if [[ ! -f "$GITHUB_TOKEN_FILE" ]]; then
        echo "ℹ️ Arquivo de token não encontrado ($GITHUB_TOKEN_FILE), pulando gh auth login."
        return 0
    fi

    if [[ ! -x "$JAIL_PATH/usr/bin/gh" ]]; then
        echo "⚠️ gh não encontrado na jail, pulando autenticação."
        return 0
    fi

    local perms
    perms="$(stat -c '%a' "$GITHUB_TOKEN_FILE")"

    if [[ "$perms" != "600" ]]; then
        echo "⚠️ Permissões inseguras em $GITHUB_TOKEN_FILE (esperado 600, encontrado $perms)."
        echo "   Corrija com: sudo chmod 600 $GITHUB_TOKEN_FILE"
        return 1
    fi

    local token
    token="$(<"$GITHUB_TOKEN_FILE")"
    token="${token//$'\n'/}"

    if [[ -z "$token" ]]; then
        echo "⚠️ Arquivo de token está vazio, pulando."
        return 0
    fi

    echo "🔑 Autenticando gh para '$USERNAME' dentro da jail..."

    # HOME é exportado no bash do HOST antes do chroot;
    # o chroot herda o ambiente do processo pai (sem precisar
    # do binário 'env' dentro da jail).
    if echo "$token" | HOME="/home/$USERNAME" chroot --userspec="$USERNAME:$USERNAME" "$JAIL_PATH" \
        gh auth login --with-token
    then
        echo "✅ gh autenticado com sucesso dentro da jail."
    else
        echo "⚠️ gh auth falhou, seguindo sem autenticar."
    fi

    unset token
}

# =========================================================
# GARANTIR REDE/DNS/TLS DENTRO DA JAIL
# =========================================================
ensure_network_in_jail() {

    echo "🌐 Garantindo DNS/TLS dentro da jail..."

    if [[ ! -s "$JAIL_PATH/etc/resolv.conf" ]]; then
        cp /etc/resolv.conf "$JAIL_PATH/etc/resolv.conf"
        echo "  ✅ resolv.conf copiado."
    else
        echo "  ✅ resolv.conf já presente."
    fi

    if [[ ! -f "$JAIL_PATH/etc/ssl/certs/ca-certificates.crt" ]]; then
        mkdir -p "$JAIL_PATH/etc/ssl/certs"
        cp /etc/ssl/certs/ca-certificates.crt "$JAIL_PATH/etc/ssl/certs/ca-certificates.crt"
        echo "  ✅ ca-certificates.crt copiado."
    else
        echo "  ✅ ca-certificates.crt já presente."
    fi

    if [[ ! -f "$JAIL_PATH/etc/hosts" ]]; then
        cp /etc/hosts "$JAIL_PATH/etc/hosts"
        echo "  ✅ hosts copiado."
    else
        echo "  ✅ hosts já presente."
    fi
}

# =========================================================
# RESUMO
# =========================================================

show_summary() {
    echo
    echo "=============================================="
    echo "✅ USUÁRIO ADMIN CRIADO"
    echo "=============================================="
    echo
    echo "👤 Usuário : $USERNAME"
    echo "🏠 HOME    : $USER_HOME"
    echo "🧸 SKEL    : $JAIL_SKEL"
    echo "🛡️ Sudo    : NOPASSWD somente na jail"
    echo "🐚 Shell   : zsh"
    if [[ -f "$GITHUB_TOKEN_FILE" ]]; then
        echo "🐙 gh auth : token lido de $GITHUB_TOKEN_FILE (ver log para status)"
    else
        echo "🐙 gh auth : não configurado (arquivo de token ausente)"
    fi
    echo "👥 Grupos  : $GROUP_NAME,$EXTRA_HOST_GROUPS"
    echo "📦 Arquivos herdados do SKEL:"
    echo "   $USER_HOME/.bashrc"
    echo "   $USER_HOME/.profile"
    echo "   $USER_HOME/.bash_logout"
    echo "   $USER_HOME/.config/"
    echo "   $USER_HOME/.gnome-template/defaults.conf"
    echo "🔑 SSH     : herdado do SKEL"
    echo "📁 Docs    : $USER_HOME/Documentos"
    echo "📁 Work    : $USER_HOME/workspace"
    echo
    echo "=============================================="
}

# =========================================================
# MAIN
# =========================================================

main() {
    validate_root
    validate_username
    validate_skel
    ensure_group_exists
    remove_existing_user
    create_user
    configure_jailkit    
    harden_home_root
    ensure_sudo_in_jail
    ensure_zsh_in_jail
    ensure_gum_installed
    configure_sudoers
    configure_home
    ensure_gh_in_jail
    ensure_network_in_jail
    configure_gh_auth    
    
    create_shared_folder \
        "$JAIL_PATH/Documentos" \
        "$USER_HOME/Documentos" \
        "$GROUP_NAME"

    create_shared_folder \
        "$JAIL_PATH/workspace" \
        "$USER_HOME/workspace" \
        "$GROUP_NAME"

    if [[ -x /usr/local/bin/jail-mounts.sh ]]; then
        /usr/local/bin/jail-mounts.sh
    else
        echo "⚠️ /usr/local/bin/jail-mounts.sh não encontrado, pulando."
    fi

    add_jail_user_to_list_persist_bind_mount
    configure_monitors
    configure_user_vscode_shortcuts
    show_summary
}

main "$@"