#!/bin/bash

# =========================================================
# 🔐 JailKit Shared User Creator
# =========================================================
# 🔥 IMPORTANTE: Esse script possui dependência direta de remove-jail-user
#
# Uso:
# ./create-jail-user <user login>
#
# Exemplo:
# ./create-jail-user codex-user
#
# 🔥 IMPORTANTE: Para scripts administrativos compartilhados no Linux, os locais mais adequados são:
#   ✅ Local Ideal para scripts administrativos (sudo) /usr/local/sbin
#   sudo cp -r create-jail-user /usr/local/sbin/create-jail-user
#
# ⚙️ Tornar script executável
#  chmod +x create-jail-user
#
# ⚙️ Permitir execução apenas para root e grupo sudo
#   sudo chown root:sudo create-jail-user
#   sudo chmod 750 create-jail-user
#
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

# Caminho do arquivo de defaults do dconf (GNOME) — edite as chaves aqui
readonly DCONF_DEFAULTS_FILE="/etc/dconf/db/local.d/00-jail-defaults"
readonly DCONF_PROFILE_FILE="/etc/dconf/profile/user"
readonly MONITORS_TEMPLATE="/etc/jailkit/skel/monitors.xml"

# Wrapper + sudoers do auto-chroot
readonly ENTER_JAIL_WRAPPER="/home/jail/usr/local/sbin/enter-jail"
readonly SUDOERS_FILE="/etc/sudoers.d/jail-users"

USERNAME="${1:-}"
USER_HOME="$JAIL_PATH/home/$USERNAME"

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
        echo "Uso: sudo create-jail-user <usuario>"
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
# 👤 CRIAR USUÁRIO
# =========================================================

create_user() {
    local full_name
    full_name="$(echo "${USERNAME%%-*}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

    useradd \
        -m \
        -c "$full_name" \
        -d "$JAIL_PATH/./home/$USERNAME" \
        -s /usr/bin/bash \
        -U \
        -G "$GROUP_NAME" \
        "$USERNAME"

    echo "$USERNAME:$DEFAULT_PASSWORD" | chpasswd >/dev/null 2>&1
}

# =========================================================
# 🔒 CONFIGURAR JAILKIT
# =========================================================

configure_jailkit() {
    echo "DEBUG: JAIL_PATH='$JAIL_PATH' USERNAME='$USERNAME'"
    jk_jailuser \
        -j "$JAIL_PATH" \
        "$USERNAME"
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
# Gerado por create-jail-user — não editar manualmente.
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

    mkdir -p \
        "$USER_HOME/.config" \
        "$USER_HOME/.cache" \
        "$USER_HOME/.local/share"

    cat > "$USER_HOME/.profile" <<EOF
if [ -n "\$DISPLAY" ]; then
    export DISPLAY=\$DISPLAY
fi
export XAUTHORITY=\$HOME/.Xauthority

[ -f ~/.bashrc ] && . ~/.bashrc
EOF

    # --- Cabeçalho com variáveis expandidas (heredoc SEM aspas) ---
    cat >> "$USER_HOME/.bashrc" <<'EOF'
# =========================================================
# 🔒 Auto-chroot — gerado por create-jail-user, não editar
# =========================================================
# Só age em shells interativos com terminal (evita jailar a sessão
# gráfica do GDM, que roda este mesmo .bashrc de forma não-interativa).
if [[ \$- == *i* ]] && [[ -t 1 ]]; then
    __jail_root="$JAIL_PATH"
    __jail_user="$USERNAME"
    __jail_dev_ino="\$(stat -c '%d:%i' "\$__jail_root" 2>/dev/null || true)"
    __my_dev_ino="\$(stat -c '%d:%i' / 2>/dev/null || true)"

    if [[ -n "\$__jail_dev_ino" ]] && [[ "\$__jail_dev_ino" != "\$__my_dev_ino" ]]; then
        exec sudo $ENTER_JAIL_WRAPPER "\$__jail_user"
    fi
    unset __jail_root __jail_user __jail_dev_ino __my_dev_ino
fi

# --- Resto do .bashrc (aliases, PS1, dashboard docker etc.) ---

export PATH=/usr/local/bin:/usr/bin:/bin
alias cls='clear'


# =========================
# EZA AS LS
# =========================

function ls() {
    command eza \
	-la \
       --group \
        --group-directories-first \
        "$@"
}


# =========================
# EZA OVERRIDE
# =========================

# ls -l
alias ll='eza -l -h --group --icons'

# ls -la
alias la='eza -la -hs --group'

# tree
alias lt='eza --tree --level=2 --group '

alias py='python3'

alias dual-audio='pactl load-module module-combine-sink sink_name=dual_audio'
alias loca='ssh dev@186.202.57.100'
alias docker-prune='docker builder prune -f'
alias docker-sys-prune='docker system prune -f'
alias cpu='cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'

# =========================
# Colorized Path with Branch
# =========================

function parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    [ -n "$branch" ] && echo " ($branch)"
}

PS1='\[\e[0;32m\][\[\e[1;34m\]\u\[\e[0m\]:\[\e[1;36m\]\w\[\e[0m\]\[\e[1;33m\]$(parse_git_branch)\[\e[0m\]\[\e[0;32m\]]\[\e[0m\]\$'

#==============================================================================
# Docker Dashboard + Gum
#==============================================================================
GREEN="\e[38;5;82m"
RED="\e[38;5;196m"
YELLOW="\e[38;5;220m"
BLUE="\e[38;5;39m"
CYAN="\e[38;5;51m"
GRAY="\e[38;5;245m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

#==============================================================================
# CONTAINERS
#==============================================================================
dps() {
    clear
    running=$(docker ps -q | wc -l)
    total=$(docker ps -aq | wc -l)
    stopped=$((total-running))

    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    printf "║ %-76s ║\n" "🐳 Docker Dashboard"
    printf "║ %-76s ║\n" "🟢 Running: $running   🔴 Stopped: $stopped   📦 Total: $total"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    printf "${BOLD}%-3s %-25s %-22s %-18s %-35s${RESET}\n" \
    "" "NAME" "STATUS" "PORTS" "IMAGE"

    printf '─%.0s' {1..110}
    echo

    docker ps -a \
    --format "{{.Names}}|{{.Status}}|{{.Ports}}|{{.Image}}" |
    while IFS="|" read -r name status ports image
    do
        # Status icon
        if [[ "$status" == Up* ]]; then
            icon="${GREEN}🟢${RESET}"
        elif [[ "$status" == Exited* ]]; then
            icon="${RED}🔴${RESET}"
        else
            icon="${YELLOW}🟡${RESET}"
        fi

        # Limita portas
        ports=$(echo "$ports" |
        sed \
        -e 's/0.0.0.0://g' \
        -e 's/\[::\]://g' \
        -e 's/\/tcp//g')

        # Se vazio
        [[ -z "$ports" ]] && ports="-"

        # Limita tamanho
        name=$(printf "%.25s" "$name")
        status=$(printf "%.22s" "$status")
        ports=$(printf "%.18s" "$ports")
        image=$(printf "%.35s" "$image")


        printf "%b %-25s %-22s %-18s %-35s\n" \
        "$icon" \
        "$name" \
        "$status" \
        "$ports" \
        "$image"
    done

    printf '─%.0s' {1..110}
    echo
}

#==============================================================================
# Docker Images Dashboard
#==============================================================================
di() {
    clear
    total=$(docker images -q | wc -l)
    echo -e "${GREEN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════════════════════════════╗"
    printf "║ %-84s ║\n" "🖼️  Docker Images"
    printf "║ %-84s ║\n" "📦 Total Images: $total"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    printf "${BOLD}%-35s %-15s %-12s %-12s %-15s${RESET}\n" \
    "REPOSITORY" "TAG" "SIZE" "CREATED" "IMAGE ID"
    printf '─%.0s' {1..95}
    echo
    docker images \
    --format "{{.Repository}}|{{.Tag}}|{{.Size}}|{{.CreatedSince}}|{{.ID}}" |

    while IFS="|" read -r repo tag size created id
    do
        # Trata imagens sem nome
        [[ "$repo" == "<none>" ]] && repo="dangling"

        # Ícone
        if [[ "$tag" == "<none>" ]]; then
            icon="${YELLOW}⚠️ ${RESET}"
            tag="none"
        else
            icon="${GREEN} 🖼️ ${RESET}"
        fi

        # Corta textos grandes
        repo=$(printf "%.35s" "$repo")
        tag=$(printf "%.15s" "$tag")
        size=$(printf "%.12s" "$size")
        created=$(printf "%.12s" "$created")
        id=$(printf "%.12s" "$id")

        printf "%b %-33s %-15s %-12s %-12s %-15s\n" \
        "$icon " \
        "$repo" \
        "$tag" \
        "$size" \
        "$created" \
        "$id"
    done

    printf '─%.0s' {1..95}
    echo
}

#==============================================================================
# VOLUMES
#==============================================================================
dv() {
    clear
    total=$(docker volume ls -q | wc -l)

    gum style \
    --border rounded \
    --border-foreground 51 \
    --padding "1 3" \
    "💾 Docker Volumes
    📦 Total: $total"

    echo
    printf "${BOLD}%-50s %-20s${RESET}\n" \
    "VOLUME" "DRIVER"

    printf '─%.0s' {1..80}
    echo
    docker volume ls \
    --format "{{.Name}}|{{.Driver}}" |
    while IFS="|" read name driver
    do

    printf "💾 %-48s %-20s\n" \
    "$name" "$driver"

    done
}

#==============================================================================
# NETWORKS
#==============================================================================
dn() {
    clear
    total=$(docker network ls -q | wc -l)

    gum style \
    --border rounded \
    --border-foreground 51 \
    --padding "1 3" \
    "🌐 Docker Networks
    📦 Total: $total"

    echo
    printf "${BOLD}%-30s %-20s %-15s${RESET}\n" \
    "NAME" "DRIVER" "SCOPE"
    printf '─%.0s' {1..80}
    echo

    docker network ls \
    --format "{{.Name}}|{{.Driver}}|{{.Scope}}" |
    while IFS="|" read name driver scope
    do

    printf "🌐 %-28s %-20s %-15s\n" \
    "$name" "$driver" "$scope"

    done
}

#==============================================================================
# INTERACTIVE COMMANDS WITH GUM
#==============================================================================
dexec() {
    container=$(docker ps --format "{{.Names}}" | gum choose --header "Escolha o container")
    [ -z "$container" ] && return

    docker exec -it "$container" bash \
    || docker exec -it "$container" sh
}

dlog() {
    container=$(docker ps --format "{{.Names}}" | gum choose --header "Logs do container")

    [ -z "$container" ] && return

    docker logs -f --tail 200 "$container"
}

drm() {
    container=$(docker ps -a --format "{{.Names}}" | gum choose --header "Remover container")
    [ -z "$container" ] && return
    gum confirm "Remover $container?" || return
    docker rm -f "$container"
}

alias cpu='cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
EOF

    touch \
        "$USER_HOME/.bash_logout" \
        "$USER_HOME/.Xauthority"

    chown -R "$USERNAME:$GROUP_NAME" "$JAIL_PATH/home/$USERNAME"

    # 700 (não 750!): como todos os jailusers compartilham o mesmo grupo
    # "$GROUP_NAME", um 750 daria a QUALQUER outro jailuser permissão de
    # leitura/entrada nesse home só por estar no grupo. 700 restringe ao
    # próprio dono.
    chmod 700 "$JAIL_PATH/home/$USERNAME"

    chmod 700 \
        "$USER_HOME/.cache" \
        "$USER_HOME/.config" \
        "$USER_HOME/.local"

    chmod 600 "$USER_HOME/.Xauthority"
}

# =========================================================
# 🎨 CONFIGURAR DESKTOP (GNOME/dconf — nível HOST, global)
# =========================================================
# Isso NÃO é por-usuário: o dconf é um banco global do sistema.
# Rodar isso garante que o arquivo de defaults exista e esteja
# aplicado, mas não precisa ser refeito a cada usuário — é
# idempotente, então não tem problema rodar sempre.
# =========================================================

configure_dconf_defaults() {

    if [[ ! -f "$DCONF_PROFILE_FILE" ]]; then
        mkdir -p "$(dirname "$DCONF_PROFILE_FILE")"
        cat > "$DCONF_PROFILE_FILE" <<'EOF'
user-db:user
system-db:local
EOF
    fi

    mkdir -p "$(dirname "$DCONF_DEFAULTS_FILE")"

    # Sempre sobrescreve com o conteúdo atual definido aqui
    cat > "$DCONF_DEFAULTS_FILE" <<'EOF'
[org/gnome/desktop/interface]
clock-format='24h'
clock-show-weekday=true
clock-show-date=true
clock-show-seconds=true
clock-show-weekday-numbers=false
color-scheme='prefer-dark'
cursor-blink-time=1200
gtk-theme='Yaru-dark'
icon-theme='Yaru-dark'

[org/gnome/desktop/datetime]
automatic-timezone=true

[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'

[org/gnome/shell/overrides]
dynamic-workspaces=false
edge-tiling=false

[org/gnome/mutter/keybindings]
toggle-tiled-left=@as []
toggle-tiled-right=@as []

[org/gnome/shell]
favorite-apps=['google-chrome.desktop', 'code.desktop', 'antigravity.desktop', 'org.gnome.Ptyxis.desktop', 'firefox_firefox.desktop', 'org.gnome.Nautilus.desktop', 'snap-store_snap-store.desktop', 'libreoffice-calc.desktop']
last-selected-power-profile='performance'
welcome-dialog-last-shown-version='50.1'

[org/gnome/shell/app-switcher]
current-workspace-only=true

[org/gnome/shell/extensions/dash-to-dock]
isolate-monitors=false
isolate-workspaces=true
dash-max-icon-size=32

[org/gnome/shell/extensions/ding]
check-x11wayland=true
keep-arranged=true

[org/gnome/shell/extensions/tiling-assistant]
focus-hint-color='rgb(211,70,21)'
last-version-installed=54
tiling-popup-all-workspace=false
[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'

[org/gnome/shell/extensions/ding]
check-x11wayland=true
keep-arranged=true
EOF

    dconf update
}

# =========================================================
# 📂 SHARED FOLDERS
# =========================================================

create_shared_folder() {

    local src="$1"
    local dst="$2"

    mkdir -p "$src"
    mkdir -p "$dst"
    chmod 2776 "$src" 2>/dev/null || true

    if ! mountpoint -q "$dst"; then
        bindfs \
        --force-user="$USERNAME" \
        --force-group="$USERNAME" \
        "$src" \
        "$dst"
    fi
    chmod 2776 "$dst"
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
# ➕ Configurar git gh auth
# =========================================================

configure_gh_auth_manual() {

    local gh_dir="$USER_HOME/.config/gh"

    mkdir -p "$gh_dir"

    cat > "$gh_dir/hosts.yml" <<EOF
github.com:
    user: $USERNAME
    oauth_token: PLACE_YOUR_TOKEN_HERE
    git_protocol: https
EOF

    chown -R "$USERNAME:$GROUP_NAME" "$gh_dir"
    chmod 770 "$USER_HOME/.config"
    chmod 770 "$gh_dir"
    chmod 660 "$gh_dir/hosts.yml"
}

# =========================================================
# 🖥️ CONFIGURAR MONITORES (template, sem depender de usuário)
# =========================================================

configure_monitors() {

    if [[ ! -f "$MONITORS_TEMPLATE" ]]; then
        echo "⚠️  $MONITORS_TEMPLATE não encontrado, pulando config de monitores."
        return 0
    fi

    cp "$MONITORS_TEMPLATE" "$USER_HOME/.config/monitors.xml"
}

# =========================================================
# 🖥️ X11
# =========================================================

configure_x11() {
    command -v xhost >/dev/null 2>&1 || return 0
    [ -n "${DISPLAY:-}" ] || return 0
    xhost +SI:localuser:"$USERNAME" >/dev/null 2>&1 || true
}

# =========================================================
# 🚀 EXECUÇÃO
# =========================================================

main() {

    validate_root
    validate_username
    ensure_group_exists
    setup_enter_jail_wrapper
    setup_sudoers
    harden_home_root
    remove_existing_user
    create_user
    configure_gh_auth_manual
    configure_jailkit
    configure_home
    configure_dconf_defaults
    create_shared_folder "$JAIL_PATH/Documentos" "$USER_HOME/Documentos"
    create_shared_folder "$JAIL_PATH/workspace" "$USER_HOME/workspace"
    add_jail_user_to_list_persist_bind_mount
    configure_monitors
    #configure_x11
    usermod -aG docker "$USERNAME"
    usermod -s /bin/bash "$USERNAME"

    echo ""
    echo "======================================"
    echo "✅ Usuário criado com sucesso"
    echo "======================================"
    echo "👤 Usuário : $USERNAME"
    echo "🏠 Jail    : $JAIL_PATH"
    echo "🔒 Terminal entra automaticamente na jail via $ENTER_JAIL_WRAPPER"
    echo ""
}

main "$@"