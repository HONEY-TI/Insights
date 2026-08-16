#!/bin/bash

# =========================================================
# 🔐 JailKit Shared User Creator
# =========================================================
# 🔥 IMPORTANTE: Esse script possui dependência direta de remove-jail-user
#
# Uso:
# ./create-user <user login>
#
# Exemplo:
# ./create-user codex-user
#
# 🔥 IMPORTANTE: Para scripts administrativos compartilhados no Linux, os locais mais adequados são:
#   ✅ Local Ideal para scripts administrativos (sudo) /usr/local/sbin
#   sudo cp -r exit /usr/local/sbin/create-user
#
# ⚙️ Tornar script executável
#  chmod +x create-user
#
# ⚙️ Permitir execução apenas para root e grupo sudo
#   sudo chown root:sudo create-user
#   sudo chmod 750 create-user
#
# Testat github connection
# ssh -T git@github.com
# =========================================================
#
# 🔒 AUTO-CHROOT NO TERMINAL
# =========================================================
# O usuário faz login gráfico (GDM) normalmente com /bin/bash real,
# fora da jail — isso é necessário pro GNOME funcionar. Mas assim que
# ele abre QUALQUER terminal interativo (GNOME Terminal, Ptyxis, ssh
# direto na conta, `su - user` etc.), o .bashrc detecta que ainda
# está "fora" da jail e se auto-substitui (`exec`) por um processo
# chrootado, de forma transparente.
#
# Isso é feito via um wrapper root (`enter-jail`) liberado por sudoers
# NOPASSWD apenas para o grupo jailusers, e apenas para chrootar como
# o próprio usuário que chamou (checado via $SUDO_USER dentro do
# wrapper — impede que um jailuser vire outro jailuser).
#
# ⚠️ Pré-requisitos que este script NÃO cobre:
#   - jailkit já inicializado na jail (jk_init com os jails necessários)
#   - /home/jail/proc e /home/jail/dev/pts montados (bind/mount), senão
#     job control e alguns programas dentro do terminal chrootado quebram
#   - pacote `bindfs` instalado (usado em create_shared_folder)
# =========================================================

set -euo pipefail

# =========================================================
# 🔐 CONFIGURAÇÕES
# =========================================================

readonly JAIL_PATH="/home/jail"
readonly GROUP_NAME="jailusers"
readonly DEFAULT_PASSWORD="7004"


# Wrapper + sudoers do auto-chroot
readonly ENTER_JAIL_WRAPPER="/usr/local/sbin/enter-jail"
readonly SUDOERS_FILE="/etc/sudoers.d/jail-users"

USERNAME="${1:-}"
readonly USER_HOME="$JAIL_PATH/./home/$USERNAME"
readonly EXTRA_HOST_GROUPS="docker,users,jailusers,gitssh"

# =========================================================
# 👑 VALIDAR ROOT
# =========================================================

validate_root() {
    [[ "$EUID" -eq 0 ]] || {
        echo "❌ Execute como root."
        exit 1
    }
}

# =========================================================
# ❌ VALIDAR USUÁRIO
# =========================================================

validate_username() {
    [[ -n "$USERNAME" ]] || {
        echo "❌ Informe o usuário."
        echo "Uso: sudo create-user <usuario>"
        exit 1
    }
}

# =========================================================
# 📦 GARANTIR DEPENDÊNCIAS
# =========================================================

ensure_group_exists() {
    getent group "$GROUP_NAME" >/dev/null || groupadd "$GROUP_NAME"
}

# =========================================================
# 🗑️ REMOVER USUÁRIO EXISTENTE
# =========================================================

remove_existing_user() {
    if id "$USERNAME" &>/dev/null; then
        echo "⚠️ Usuário já existe."
        read -rp "Remover e recriar? (s/N): " CONFIRM

        if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
            remove-jail-user "$USERNAME" || true
        else
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
# 👤 CRIAR USUÁRIO
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
# 🔒 CONFIGURAR JAILKIT
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
# 🔐 WRAPPER + SUDOERS PARA AUTO-CHROOT NO TERMINAL
# =========================================================
# Idempotente e global (não é por-usuário) — pode rodar sempre.
# =========================================================

setup_enter_jail_wrapper() {
    cat > "$ENTER_JAIL_WRAPPER" <<'WRAPPER_EOF'
#!/bin/bash
# enter-jail — entra no chroot da jail como o usuário informado.
# Só deve ser chamado via sudo por membros do grupo jailusers.
set -euo pipefail

JAIL_PATH="/home/jail"
TARGET_USER="${1:-}"

[[ -n "$TARGET_USER" ]] || { echo "Uso: enter-jail <usuario>" >&2; exit 1; }

# Impede que um jailuser chroote como outro jailuser: só pode "entrar"
# na jail como ele mesmo (SUDO_USER é setado pelo sudo, não pelo chamador).
if [[ -z "${SUDO_USER:-}" ]] || [[ "$TARGET_USER" != "$SUDO_USER" ]]; then
    echo "❌ Só é permitido entrar na jail como você mesmo." >&2
    exit 1
fi

getent passwd "$TARGET_USER" >/dev/null || { echo "❌ Usuário inválido." >&2; exit 1; }

# chroot NÃO reinicializa o ambiente como login/su fariam: HOME, USER e
# LOGNAME continuam sendo os do processo pai (ex: /home/jail/home/user,
# caminho que não existe mais dentro do novo root). Forçamos aqui os
# valores corretos relativos ao NOVO root ($JAIL_PATH vira "/"), senão
# `cd ~`, leitura do .profile e programas que confiam em $HOME quebram
# — e, pior, um HOME errado pode fazer o usuário cair fora do próprio
# home (ex: na raiz da jail), o que é exatamente o que NÃO queremos.
TARGET_HOME="/home/$TARGET_USER"

exec /usr/bin/env -i \
    HOME="$TARGET_HOME" \
    USER="$TARGET_USER" \
    LOGNAME="$TARGET_USER" \
    TERM="${TERM:-xterm-256color}" \
    DISPLAY="${DISPLAY:-}" \
    /usr/bin/chroot --userspec="$TARGET_USER:$TARGET_USER" "$JAIL_PATH" /bin/bash --login
WRAPPER_EOF

    chown root:root "$ENTER_JAIL_WRAPPER"
    chmod 750 "$ENTER_JAIL_WRAPPER"
}

setup_sudoers() {
    local tmp
    tmp="$(mktemp)"

    cat > "$tmp" <<EOF
# Gerado por create-user — não editar manualmente.
%$GROUP_NAME ALL=(root) NOPASSWD: $ENTER_JAIL_WRAPPER *
EOF

    if visudo -cf "$tmp" >/dev/null 2>&1; then
        install -m 0440 -o root -g root "$tmp" "$SUDOERS_FILE"
    else
        echo "❌ Arquivo sudoers gerado é inválido, abortando por segurança." >&2
        rm -f "$tmp"
        exit 1
    fi

    rm -f "$tmp"
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
# 🔒 ENDURECER /home DENTRO DA JAIL
# =========================================================
# Idempotente e global (não é por-usuário) — roda sempre.
# Sem isso, "ls /home" dentro da jail lista o login de TODOS os
# usuários (enumeração), mesmo que cada home individual já esteja
# em 700. 711 = dono (root) pode tudo; demais só conseguem "atravessar"
# (cd) um subdiretório se já souberem o nome exato — não conseguem
# listar (ls) o conteúdo de /home nem entrar no home alheio, pois o
# home alheio em si está em 700.
# =========================================================

harden_home_root() {
    local home_root="$JAIL_PATH/home"
    mkdir -p "$home_root"
    chown root:root "$home_root"
    chmod 711 "$home_root"
}

# =========================================================
# 🏠 CONFIGURAR HOME DENTRO DA JAIL
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
# 📂 SHARED FOLDERS
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
# ➕ Adicionar usuário a lista de persistencia de mount
# =========================================================
add_jail_user_to_list_persist_bind_mount() {
    local file="/home/jail/etc/jail-users.list"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if ! grep -qx "$USERNAME" "$file"; then
        echo "$USERNAME" >> "$file"
    fi
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
    echo "🏠 Jail    : $JAIL_PATH"
    echo "🔒 Terminal entra automaticamente na jail via $ENTER_JAIL_WRAPPER"
    echo ""
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
# 🚀 MAIN
# =========================================================

main() {

    validate_root
    validate_username
    validate_skel
    ensure_group_exists
    remove_existing_user
    create_user
    setup_sudoers
    setup_enter_jail_wrapper
    harden_home_root            
    ensure_sudo_in_jail
    ensure_zsh_in_jail
    ensure_gum_installed
    configure_home    
    configure_jailkit
    ensure_network_in_jail
    configure_gh_auth     
    create_shared_folder "$JAIL_PATH/Documentos" "$USER_HOME/Documentos"
    create_shared_folder "$JAIL_PATH/workspace" "$USER_HOME/workspace"
    add_jail_user_to_list_persist_bind_mount
    configure_monitors
    configure_user_vscode_shortcuts
    show_summary
}

main "$@"