#!/bin/bash

# =========================================================
# 🔐 JailKit Shared ADMIN User Creator (sudo SOMENTE dentro da jail)
# =========================================================
# 🔥 IMPORTANTE: Esse script possui dependência direta de remove-jail-user
#
# Diferença em relação ao create-jail-user "comum":
#   - Usuário tem sudo (NOPASSWD) SOMENTE dentro do ambiente da jail
#   - Usuário NUNCA é adicionado ao grupo "sudo" do sistema real e o
#     script NUNCA toca em /etc/sudoers ou /etc/sudoers.d do host
#     (fora da jail ele é um usuário comum, sem qualquer privilégio extra)
#   - Grupos do usuário: jailusers, grp-alex, docker, vboxusers, users
#   - O script tenta garantir que o binário `sudo` esteja copiado
#     para dentro da jail via jk_cp
#   - O script também garante que `gum` esteja instalado no host
#     e disponível dentro da jail (usado por dv, dn, dexec, dlog, drm)
#   - .bashrc completo com dashboard docker (dps, di, dv, dn, dexec,
#     dlog, drm), aliases eza, prompt com branch git, etc.
#
# Uso:
# sudo ./create-jail-su-user <user login>
#
# Exemplo:
# sudo ./create-jail-su-user codex-admin
#
# 🔥 IMPORTANTE: Para scripts administrativos compartilhados no Linux, os locais mais adequados são:
#   ✅ Local Ideal para scripts administrativos (sudo) /usr/local/sbin
#   sudo cp -r create-jail-su-user /usr/local/sbin/create-jail-su-user
#
# ⚙️ Tornar script executável
#  chmod +x create-jail-su-user
#
# ⚙️ Permitir execução apenas para root e grupo sudo
#   sudo chown root:sudo create-jail-su-user
#   sudo chmod 750 create-jail-su-user
#
# =========================================================

set -euo pipefail

# =========================================================
# 🔐 CONFIGURAÇÕES
# =========================================================

readonly JAIL_PATH="/home/jail"
readonly GROUP_NAME="jailusers"
readonly DEFAULT_PASSWORD="7004"
readonly ADMIN_PATH="/home/admin"
# Grupos do sistema real que o usuário deve ter.
# ⚠️ "sudo" NÃO está nessa lista de propósito: o usuário não deve
# ter privilégio de sudo fora da jail.
readonly EXTRA_HOST_GROUPS="grp-admin,docker,vboxusers,users"

USERNAME="${1:-}"
USER_HOME="$JAIL_PATH/home/$USERNAME"

# Caminho do arquivo de defaults do dconf (GNOME) — edite as chaves aqui
readonly DCONF_DEFAULTS_FILE="/etc/dconf/db/local.d/00-jail-defaults"
readonly DCONF_PROFILE_FILE="/etc/dconf/profile/user"
readonly MONITORS_TEMPLATE="/etc/jailkit/skel/monitors.xml"

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
        echo "Uso: sudo create-jail-su-user <usuario>"
        exit 1
    }
}

# =========================================================
# 📦 GARANTIR DEPENDÊNCIAS (grupos do sistema real)
# =========================================================

ensure_group_exists() {
    getent group "$GROUP_NAME" >/dev/null || groupadd "$GROUP_NAME"

    local IFS=","
    for g in $EXTRA_HOST_GROUPS; do
        getent group "$g" >/dev/null || {
            echo "⚠️ Grupo '$g' não existe no sistema, criando..."
            groupadd "$g"
        }
    done

    # 🔒 Garantia extra: mesmo que alguém adicione "sudo" na lista
    # EXTRA_HOST_GROUPS por engano, isso é bloqueado aqui.
    if [[ ",$EXTRA_HOST_GROUPS," == *",sudo,"* ]]; then
        echo "❌ 'sudo' não pode estar em EXTRA_HOST_GROUPS. Abortando."
        exit 1
    fi
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
    local full_name="$(echo "${USERNAME%%-*}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

    useradd \
        -m \
        -c "$full_name" \
        -d "$JAIL_PATH/./home/$USERNAME" \
        -s /usr/bin/bash \
        -U \
        -G "$GROUP_NAME,$EXTRA_HOST_GROUPS" \
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
# 🧰 GARANTIR SUDO DENTRO DA JAIL (apenas dentro do chroot)
# =========================================================

ensure_sudo_in_jail() {

    if [[ -x "$JAIL_PATH/usr/bin/sudo" ]]; then
        echo "✅ sudo já presente na jail."
    else
        echo "🔎 Verificando/possibilitando sudo dentro da jail..."

        if command -v jk_cp >/dev/null 2>&1; then
            if jk_cp -v -j "$JAIL_PATH" sudo 2>/dev/null; then
                echo "✅ sudo copiado para dentro da jail via jk_cp (seção do jk_init.ini)."
            elif jk_cp -v -j "$JAIL_PATH" /usr/bin/sudo 2>/dev/null; then
                echo "✅ sudo copiado para dentro da jail via jk_cp (binário direto)."
            else
                echo "⚠️ Não foi possível copiar o sudo automaticamente."
                echo "   Adicione manualmente uma seção [sudo] no /etc/jailkit/jk_init.ini, ex:"
                echo ""
                echo "   [sudo]"
                echo "   paths = /usr/bin/sudo, /etc/sudoers, /etc/sudoers.d/"
                echo ""
                echo "   E rode novamente, ou execute manualmente:"
                echo "   jk_cp -v -j $JAIL_PATH sudo"
            fi
        else
            echo "⚠️ jk_cp não encontrado no PATH. Pulei a cópia automática do sudo para a jail."
        fi
    fi

    mkdir -p "$JAIL_PATH/etc/sudoers.d"
    if [[ ! -f "$JAIL_PATH/etc/sudoers" ]]; then
        touch "$JAIL_PATH/etc/sudoers"
        chmod 440 "$JAIL_PATH/etc/sudoers"
    fi
}

# =========================================================
# 🧸 GARANTIR QUE O GUM ESTÁ INSTALADO (host + jail)
# =========================================================
# O .bashrc usa gum em dv, dn, dexec, dlog, drm. Sem o binário
# dentro da jail, essas funções falham com "command not found".

ensure_gum_installed() {

    # ---- 1) Garantir gum instalado no HOST ----
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

        if command -v gum >/dev/null 2>&1; then
            echo "✅ gum instalado no host."
        else
            echo "⚠️ Não foi possível instalar o gum automaticamente no host."
            echo "   Instale manualmente: https://github.com/charmbracelet/gum#installation"
        fi
    else
        echo "✅ gum já está instalado no host."
    fi

    # ---- 2) Garantir gum disponível DENTRO da jail ----
    if [[ -x "$JAIL_PATH/usr/bin/gum" || -x "$JAIL_PATH/usr/local/bin/gum" ]]; then
        echo "✅ gum já presente na jail."
        return 0
    fi

    if ! command -v gum >/dev/null 2>&1; then
        echo "⚠️ gum não está disponível no host, não é possível copiar para a jail."
        return 0
    fi

    echo "🔎 Copiando gum para dentro da jail..."

    if command -v jk_cp >/dev/null 2>&1; then
        if jk_cp -v -j "$JAIL_PATH" gum 2>/dev/null; then
            echo "✅ gum copiado para a jail via jk_cp (seção do jk_init.ini)."
        elif jk_cp -v -j "$JAIL_PATH" "$(command -v gum)" 2>/dev/null; then
            echo "✅ gum copiado para a jail via jk_cp (binário direto)."
        else
            echo "⚠️ Não foi possível copiar o gum automaticamente para a jail."
            echo "   Adicione uma seção [gum] no /etc/jailkit/jk_init.ini, ex:"
            echo ""
            echo "   [gum]"
            echo "   paths = $(command -v gum)"
            echo ""
            echo "   E rode novamente, ou execute manualmente:"
            echo "   jk_cp -v -j $JAIL_PATH gum"
        fi
    else
        echo "⚠️ jk_cp não encontrado no PATH. Pulei a cópia automática do gum para a jail."
    fi
}

# =========================================================
# 🛡️ LIBERAR SUDO PARA O USUÁRIO — SOMENTE DENTRO DA JAIL
# =========================================================

configure_sudoers() {

    local jail_rule="$JAIL_PATH/etc/sudoers.d/90-$USERNAME"

    if [[ -d "$JAIL_PATH/etc/sudoers.d" ]]; then
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$jail_rule"
        chmod 440 "$jail_rule"
        echo "✅ Permissão de sudo (NOPASSWD) concedida para $USERNAME dentro da jail."
    else
        echo "⚠️ $JAIL_PATH/etc/sudoers.d não existe. Regra de sudo da jail não foi criada."
    fi
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

    cat > "$USER_HOME/.bashrc" <<'EOF'
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

    chmod 750 "$JAIL_PATH/home/$USERNAME"

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
    local group="${3:-grp-alex}"   # Grupo padrão

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

    chmod 2776 "$dst"
}

# =========================================================
# ➕ Adicionar usuário à lista de persistência de mount
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

    [ -n "$DISPLAY" ] || return 0

    xhost +SI:localuser:"$USERNAME" >/dev/null 2>&1 || true
}

# =========================================================
# 🚀 EXECUÇÃO
# =========================================================

main() {

    validate_root
    validate_username
    ensure_group_exists
    remove_existing_user
    create_user
    configure_gh_auth_manual
    configure_jailkit
    ensure_sudo_in_jail
    ensure_gum_installed
    configure_sudoers
    configure_home    
    configure_dconf_defaults
    create_shared_folder "$JAIL_PATH/Documentos" "$USER_HOME/Shared_Documentos" "$GROUP_NAME"
    /usr/local/bin/jail-mounts.sh
    add_jail_user_to_list_persist_bind_mount
    #configure_x11
    usermod -s /bin/bash "$USERNAME"

    echo ""
    echo "======================================"
    echo "✅ Usuário ADMIN (sudo somente na jail) criado"
    echo "======================================"
    echo "👤 Usuário : $USERNAME"
    echo "🏠 Jail    : $JAIL_PATH"
    echo "🛡️  Sudo    : NOPASSWD:ALL — SOMENTE dentro da jail"
    echo "👥 Grupos  : $GROUP_NAME, $EXTRA_HOST_GROUPS"
    echo ""
}

main "$@"

