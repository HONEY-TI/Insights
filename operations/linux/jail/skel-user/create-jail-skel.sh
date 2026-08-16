#!/bin/bash
# =========================================================
# 🧸 JailKit SKEL Builder
# =========================================================
#
# Cria /home/jail/etc/skel a partir de um usuário modelo.
#
# O SKEL é usado somente para NOVOS usuários.
#
# IMPORTANTE:
#   - arquivos copiados são independentes;
#   - alterações futuras no SKEL não alteram usuários existentes;
#   - .ssh é uma exceção: permanece compartilhado universalmente
#     através de /ssh dentro da jail.
#
# Uso:
#
#   sudo build-jail-skel <usuario-modelo>
#
# Exemplo:
#
#   sudo build-jail-skel alex
#
# =========================================================

set -euo pipefail

# =========================================================
# CONFIGURAÇÃO
# =========================================================

readonly JAIL_PATH="/home/jail"
readonly JAIL_SKEL="$JAIL_PATH/etc/skel"

USERNAME="${1:-}"

readonly USER_HOME="/home/$USERNAME"

# =========================================================
# CORES
# =========================================================

readonly GREEN='\033[38;5;82m'
readonly RED='\033[38;5;196m'
readonly YELLOW='\033[38;5;220m'
readonly BLUE='\033[38;5;39m'
readonly RESET='\033[0m'

# =========================================================
# ROOT
# =========================================================

validate_root() {

    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}❌ Execute como root.${RESET}"
        exit 1
    fi
}

# =========================================================
# ARGUMENTOS
# =========================================================

validate_arguments() {

    if [[ -z "$USERNAME" ]]; then

        echo "Uso:"
        echo
        echo "  sudo build-jail-skel <usuario-modelo>"
        echo

        exit 1
    fi
}

# =========================================================
# VALIDAR USUÁRIO
# =========================================================

validate_user() {

    if ! id "$USERNAME" >/dev/null 2>&1; then

        echo -e "${RED}❌ Usuário '$USERNAME' não existe no host.${RESET}"

        exit 1
    fi

    if [[ ! -d "$USER_HOME" ]]; then

        echo -e "${RED}❌ HOME da jail não encontrado:${RESET}"
        echo "   $USER_HOME"

        exit 1
    fi
}

# =========================================================
# CONFIRMAÇÃO
# =========================================================

confirm_replace() {

    if [[ -d "$JAIL_SKEL" ]]; then

        echo -e "${YELLOW}⚠️ O SKEL atual será substituído:${RESET}"
        echo
        echo "  $JAIL_SKEL"
        echo

        read -rp "Continuar? (s/N): " answer

        if [[ ! "$answer" =~ ^[Ss]$ ]]; then

            echo "Operação cancelada."

            exit 0
        fi
    fi
}

# =========================================================
# PREPARAR SKEL
# =========================================================

prepare_skel() {

    echo "🧹 Preparando SKEL..."

    rm -rf "$JAIL_SKEL"

    mkdir -p "$JAIL_SKEL"
}

# =========================================================
# COPIAR ARQUIVO
# =========================================================

copy_file() {

    local source="$1"
    local destination="$2"

    if [[ -f "$source" ]]; then

        mkdir -p "$(dirname "$destination")"

        cp -a "$source" "$destination"

        echo "  📄 $destination"

    else

        echo "  ⚠️ Não encontrado: $source"
    fi
}

# =========================================================
# COPIAR DIRETÓRIO
# =========================================================

copy_directory() {

    local source="$1"
    local destination="$2"

    if [[ -d "$source" ]]; then

        mkdir -p "$destination"

        cp -a "$source/." "$destination/"

        echo "  📁 $destination"

    else

        echo "  ⚠️ Não encontrado: $source"
    fi
}

# =========================================================
# SHELL
# =========================================================

copy_shell_configuration() {

    echo
    echo "🐚 Configuração de shell"
    echo

    copy_file \
        "$USER_HOME/.bashrc" \
        "$JAIL_SKEL/.bashrc"

    copy_file \
        "$USER_HOME/.bash_logout" \
        "$JAIL_SKEL/.bash_logout"

    copy_file \
        "$USER_HOME/.profile" \
        "$JAIL_SKEL/.profile"

    copy_file \
        "$USER_HOME/.zshrc" \
        "$JAIL_SKEL/.zshrc"

    copy_file \
        "$USER_HOME/.zsh_aliases" \
        "$JAIL_SKEL/.zsh_aliases"
}

# =========================================================
# ESTRUTURA DE DIRETÓRIOS
# =========================================================

copy_user_directories() {

    echo
    echo "📁 Estrutura inicial"
    echo

    # -----------------------------------------------------
    # .virtual-vms
    # -----------------------------------------------------

    if [[ -d "$USER_HOME/.virtual-vms" ]]; then

        mkdir -p "$JAIL_SKEL/.virtual-vms"

        echo "  📁 .virtual-vms"

    fi

    # -----------------------------------------------------
    # .local/bin
    # -----------------------------------------------------

    if [[ -d "$USER_HOME/.local/bin" ]]; then

        mkdir -p "$JAIL_SKEL/.local/bin"

        echo "  📁 .local/bin"

    fi

    # -----------------------------------------------------
    # .local/share
    # -----------------------------------------------------

    if [[ -d "$USER_HOME/.local/share" ]]; then

        mkdir -p "$JAIL_SKEL/.local/share"

        echo "  📁 .local/share"

    fi
}

# =========================================================
# VSCODE
# =========================================================

copy_vscode_configuration() {

    local source="$USER_HOME/.config/Code/User"

    if [[ ! -d "$source" ]]; then

        echo
        echo "ℹ️ Configuração do VS Code não encontrada."

        return 0
    fi

    echo
    echo "💻 Configuração inicial do VS Code"
    echo

    mkdir -p "$JAIL_SKEL/.config/Code/User"

    # -----------------------------------------------------
    # Arquivos explicitamente considerados configuração
    # inicial.
    # -----------------------------------------------------

    if [[ -f "$source/keybindings.json" ]]; then

        cp -a \
            "$source/keybindings.json" \
            "$JAIL_SKEL/.config/Code/User/keybindings.json"

        echo "  📄 keybindings.json"
    fi

    if [[ -f "$source/settings.json" ]]; then

        cp -a \
            "$source/settings.json" \
            "$JAIL_SKEL/.config/Code/User/settings.json"

        echo "  📄 settings.json"
    fi

    if [[ -d "$source/snippets" ]]; then

        cp -a \
            "$source/snippets" \
            "$JAIL_SKEL/.config/Code/User/"

        echo "  📁 snippets/"
    fi
}

# =========================================================
# SSH COMPARTILHADO
# =========================================================
#
# NÃO copia as chaves.
#
# A jail possui:
#
#   /home/jail/ssh
#
# Dentro do chroot isso é:
#
#   /ssh
#
# Portanto todos os usuários receberão:
#
#   ~/.ssh -> /ssh
#
# =========================================================

configure_shared_ssh() {

    echo
    echo "🔑 Configurando SSH compartilhado"
    echo

    rm -rf "$JAIL_SKEL/.ssh"
    ln -s "$JAIL_PATH/etc/ssh" "$JAIL_SKEL/.ssh"

    echo "  🔗 .ssh -> /ssh"
}

# =========================================================
# EXCLUSÕES EXPLÍCITAS
# =========================================================
#
# Esses elementos NÃO entram no SKEL.
#
# Eles podem existir no usuário modelo, mas não devem ser
# transformados em configuração inicial de novos usuários.
# =========================================================

remove_unwanted_content() {

    echo
    echo "🧹 Aplicando exclusões"
    echo

    rm -rf \
        "$JAIL_SKEL/.cache" \
        "$JAIL_SKEL/.Xauthority"

    echo "  🗑️ .cache"
    echo "  🗑️ .Xauthority"
}

# =========================================================
# PERMISSÕES
# =========================================================

configure_permissions() {

    echo
    echo "🔐 Configurando permissões"
    echo

    chown -R root:root "$JAIL_SKEL"

    chmod 755 "$JAIL_SKEL"

    # Arquivos normais do SKEL

    find "$JAIL_SKEL" \
        -type f \
        -exec chmod 644 {} \;

    # Diretórios

    find "$JAIL_SKEL" \
        -type d \
        -exec chmod 755 {} \;

    # O symlink .ssh não precisa de chmod.
}

# =========================================================
# VALIDAR RESULTADO
# =========================================================

validate_result() {

    echo
    echo "🔎 Validando SKEL"
    echo

    local required_files=(
        ".profile"
        ".bashrc"
        ".zshrc"
        ".zsh_aliases"
    )

    local file

    for file in "${required_files[@]}"; do

        if [[ -f "$JAIL_SKEL/$file" ]]; then

            echo -e "${GREEN}  ✅ $file${RESET}"

        else

            echo -e "${YELLOW}  ⚠️ $file ausente${RESET}"
        fi
    done

    # -----------------------------------------------------
    # SSH
    # -----------------------------------------------------

    if [[ -L "$JAIL_SKEL/.ssh" ]]; then

        local target

        target="$(readlink "$JAIL_SKEL/.ssh")"


        if [[ "$target" == "/ssh" ]]; then
            echo -e "${RED}  ❌ .ssh aponta para: $target${RESET}"            

        else
            echo -e "${GREEN}  ✅ .ssh -> /ssh${RESET}"
            return 1
        fi

    else

        echo -e "${RED}  ❌ .ssh não é um symlink${RESET}"

        return 1
    fi
}

# =========================================================
# RESUMO
# =========================================================

show_summary() {

    echo
    echo "=============================================="
    echo -e "${GREEN}✅ SKEL criado com sucesso${RESET}"
    echo "=============================================="
    echo
    echo "👤 Usuário modelo:"
    echo "   $USERNAME"
    echo
    echo "📦 SKEL:"
    echo "   $JAIL_SKEL"
    echo
    echo "🔑 SSH compartilhado:"
    echo "   $JAIL_SKEL/.ssh -> /ssh"
    echo
    echo "📋 Conteúdo:"
    echo

    ls -la "$JAIL_SKEL"

    echo
    echo "=============================================="
}

# =========================================================
# 🎨 GNOME / DCONF
# =========================================================
#
# Cria:
#
#   /home/jail/etc/skel/.gnome-template/defaults.conf
#
# usando o dconf do usuário do HOST informado.
#
# =========================================================

configure_gnome_template() {

    local gnome_template_dir="$JAIL_SKEL/.gnome-template"
    local gnome_template="$gnome_template_dir/defaults.conf"
    local gnome_tmp

    echo
    echo "🎨 Criando template GNOME..."
    echo

    mkdir -p "$gnome_template_dir"

    gnome_tmp="$(mktemp)"

    if runuser -u "$USERNAME" -- \
        env HOME="$USER_HOME" \
        dconf dump /org/gnome/ > "$gnome_tmp"
    then

        cp "$gnome_tmp" "$gnome_template"

        chmod 644 "$gnome_template"

        echo "   ✅ $gnome_template"

    else

        echo "   ⚠️ Não foi possível obter o dconf de $USERNAME"

        rm -f "$gnome_tmp"
        return 1
    fi

    rm -f "$gnome_tmp"
}
# =========================================================
# 📦 FLATPAK — COMPARTILHAR INSTALAÇÃO SYSTEM-WIDE NA JAIL
# =========================================================
# Compartilha /var/lib/flatpak do host com a jail e garante
# o binário flatpak disponível dentro dela.
# =========================================================
ensure_flatpak_in_jail() {

    echo "📦 Configurando Flatpak compartilhado na jail..."

    if ! command -v flatpak >/dev/null 2>&1; then
        echo "⚠️ flatpak não encontrado no host."
        return 0
    fi

    # -----------------------------------------------------
    # Repositório Flatpak compartilhado
    # -----------------------------------------------------

    mkdir -p "$JAIL_PATH/var/lib"

    if [[ -L "$JAIL_PATH/var/lib/flatpak" ]]; then
        rm -f "$JAIL_PATH/var/lib/flatpak"
    fi

    if [[ -e "$JAIL_PATH/var/lib/flatpak" && ! -d "$JAIL_PATH/var/lib/flatpak" ]]; then
        rm -rf "$JAIL_PATH/var/lib/flatpak"
    fi

    if [[ ! -e "$JAIL_PATH/var/lib/flatpak" ]]; then
        ln -s /var/lib/flatpak "$JAIL_PATH/var/lib/flatpak"
    fi

    # -----------------------------------------------------
    # Exports Flatpak
    # -----------------------------------------------------

    mkdir -p "$JAIL_PATH/var/lib/flatpak/exports/bin"
    mkdir -p "$JAIL_PATH/var/lib/flatpak/exports/share/applications"
    mkdir -p "$JAIL_PATH/var/lib/flatpak/exports/share/icons"

    # -----------------------------------------------------
    # Garantir comando flatpak dentro da jail
    # -----------------------------------------------------

    if [[ ! -x "$JAIL_PATH/usr/bin/flatpak" ]]; then

        if command -v jk_cp >/dev/null 2>&1; then

            if jk_cp -v -j "$JAIL_PATH" flatpak 2>/dev/null; then
                echo "  ✅ flatpak copiado para a jail."

            elif jk_cp -v -j "$JAIL_PATH" /usr/bin/flatpak 2>/dev/null; then
                echo "  ✅ flatpak copiado para a jail."

            else
                echo "  ⚠️ Não foi possível copiar flatpak para a jail."
            fi

        else
            echo "  ⚠️ jk_cp não encontrado."
        fi

    else
        echo "  ✅ flatpak já existe na jail."
    fi

    echo "  📦 Repositório: /var/lib/flatpak"
    echo "  🔗 Compartilhado: HOST → JAIL"

    echo "✅ Flatpak system-wide configurado na jail."
}

# =========================================================
# 🧩 EXTENSÃO GNOME — INSTALAÇÃO SYSTEM-WIDE (HOST + JAIL)
# =========================================================
# Copia a extensão do usuário modelo para os dois caminhos
# system-wide de extensões:
#
#   - /usr/share/gnome-shell/extensions            (HOST real,
#     lido por sessões gráficas GNOME via GDM)
#
#   - $JAIL_PATH/usr/share/gnome-shell/extensions  (dentro da
#     jail, lido por processos chrootados via SSH/JailKit)
#
# UUID descoberto via D-Bus da sessão ativa do usuário modelo,
# em vez de glob no nome do diretório.
# =========================================================

install_gnome_extension_systemwide() {

    local host_ext_root="$USER_HOME/.local/share/gnome-shell/extensions"

    local targets=(
        "/usr/share/gnome-shell/extensions"
        "$JAIL_PATH/usr/share/gnome-shell/extensions"
    )

    if [[ ! -d "$host_ext_root" ]]; then
        echo "⚠️ Nenhuma extensão encontrada em $host_ext_root"
        return 0
    fi

    rm -f /tmp/.installed_extension_uuids
    touch /tmp/.installed_extension_uuids

    # -----------------------------------------------------
    # D-Bus da sessão ativa do usuário modelo
    # -----------------------------------------------------

    local uid bus_addr
    uid="$(id -u "$USERNAME")"
    bus_addr="unix:path=/run/user/$uid/bus"

    if [[ ! -S "/run/user/$uid/bus" ]]; then
        echo "⚠️ Sessão D-Bus de '$USERNAME' não encontrada em /run/user/$uid/bus"
        echo "   (o usuário precisa estar com uma sessão gráfica ativa)"
        return 1
    fi

    local enabled_uuids
    enabled_uuids="$(
        runuser -u "$USERNAME" -- \
            env HOME="$USER_HOME" \
                XDG_RUNTIME_DIR="/run/user/$uid" \
                DBUS_SESSION_BUS_ADDRESS="$bus_addr" \
            gnome-extensions list --enabled \
            | grep -iE 'resource|monitor' || true
    )"

    if [[ -z "$enabled_uuids" ]]; then
        echo "⚠️ Nenhuma extensão 'resource/monitor' habilitada para $USERNAME."
        return 1
    fi

    local found=0
    local uuid
    local target

    while IFS= read -r uuid; do

        [[ -n "$uuid" ]] || continue

        local uuid_dir="$host_ext_root/$uuid"

        if [[ ! -d "$uuid_dir" ]]; then
            echo "⚠️ UUID '$uuid' habilitado, mas diretório não encontrado em $host_ext_root"
            continue
        fi

        echo "🧩 Instalando extensão: $uuid"

        for target in "${targets[@]}"; do

            mkdir -p "$target"

            rm -rf "$target/$uuid"
            cp -a "$uuid_dir" "$target/$uuid"

            chown -R root:root "$target/$uuid"
            find "$target/$uuid" -type d -exec chmod 755 {} \;
            find "$target/$uuid" -type f -exec chmod 644 {} \;

            echo "   ✅ $target/$uuid"
        done

        echo "$uuid" >> /tmp/.installed_extension_uuids

        found=1

    done <<< "$enabled_uuids"

    if [[ "$found" -eq 0 ]]; then
        echo "⚠️ Nenhuma extensão foi instalada."
        return 1
    fi

    echo "✅ Extensão(ões) instalada(s) em HOST + JAIL."
}

# =========================================================
# ⚙️ DCONF SYSTEM-WIDE — HABILITAR EXTENSÃO (HOST + JAIL)
# =========================================================
# Grava enabled-extensions como padrão do sistema, tanto para
# sessões gráficas reais (host) quanto para processos chrootados
# (jail via SSH/JailKit). Compila as duas bases via 'dconf update'
# rodando SEMPRE no host, apontando o destino em cada chamada.
# =========================================================

configure_dconf_systemwide_extension() {

    if [[ ! -f /tmp/.installed_extension_uuids ]]; then
        echo "⚠️ Nenhum UUID de extensão coletado. Pulei dconf."
        return 1
    fi

    if ! command -v dconf >/dev/null 2>&1; then
        echo "⚠️ 'dconf' não encontrado no host. Não foi possível compilar a base."
        return 1
    fi

    local uuids_formatted
    uuids_formatted="$(sed "s/.*/'&'/" /tmp/.installed_extension_uuids | paste -sd, -)"

    local roots=(
        ""              # HOST real (raiz vazia = /etc/dconf)
        "$JAIL_PATH"    # JAIL
    )

    local root
    local overall_ok=1

    for root in "${roots[@]}"; do

        local etc_dir="${root}/etc/dconf"
        local db_dir="$etc_dir/db"
        local dconf_db_dir="$db_dir/local.d"
        local dconf_lock_dir="$db_dir/locks"
        local profile_dir="$etc_dir/profile"

        mkdir -p "$dconf_db_dir" "$dconf_lock_dir" "$profile_dir"

        if [[ ! -f "$profile_dir/user" ]]; then
            cat > "$profile_dir/user" <<'EOF'
user-db:user
system-db:local
EOF
        fi

        cat > "$dconf_db_dir/00-extensions" <<EOF
[org/gnome/shell]
enabled-extensions=[$uuids_formatted]
EOF

        cat > "$dconf_lock_dir/extensions" <<'EOF'
/org/gnome/shell/enabled-extensions
EOF

        # ---------------------------------------------------
        # Compilar a base. Sem argumento = base padrão do
        # sistema (host real). Com argumento = base da jail.
        # ---------------------------------------------------

        if [[ -z "$root" ]]; then
            if dconf update; then
                echo "✅ dconf system-wide aplicado no HOST."
            else
                echo "⚠️ Falha ao rodar 'dconf update' no HOST."
                overall_ok=0
            fi
        else
            if dconf update "$db_dir"; then
                echo "✅ dconf system-wide aplicado na JAIL ($db_dir)."
            else
                echo "⚠️ Falha ao rodar 'dconf update' apontando para $db_dir"
                overall_ok=0
            fi
        fi

    done

    rm -f /tmp/.installed_extension_uuids

    if [[ "$overall_ok" -eq 1 ]]; then
        echo "✅ enabled-extensions aplicado (HOST + JAIL)."
    else
        echo "⚠️ Uma ou mais bases dconf não foram compiladas com sucesso."
        return 1
    fi
}

# =========================================================
# 🖥️ TERMINAL (PTYXIS) — PERSISTIR PERFIL SYSTEM-WIDE
# =========================================================
# Exporta o perfil de terminal configurado pelo usuário modelo
# e aplica como padrão system-wide (HOST + JAIL), para que
# todo novo usuário já herde o mesmo perfil/atalhos/cores.
# =========================================================
readonly TERMINAL_DCONF_PATH="/org/gnome/Ptyxis/"
configure_terminal_profile_systemwide() {

    echo
    echo "🖥️ Exportando perfil do Terminal (Ptyxis)..."
    echo

    local dump_tmp rewritten_tmp
    dump_tmp="$(mktemp)"
    rewritten_tmp="$(mktemp)"

    if ! runuser -u "$USERNAME" -- \
        env HOME="$USER_HOME" \
        dconf dump "$TERMINAL_DCONF_PATH" > "$dump_tmp"
    then
        echo "⚠️ Não foi possível exportar configurações do terminal de $USERNAME."
        rm -f "$dump_tmp" "$rewritten_tmp"
        return 1
    fi

    if [[ ! -s "$dump_tmp" ]]; then
        echo "⚠️ Dump do terminal veio vazio. Nada a aplicar."
        rm -f "$dump_tmp" "$rewritten_tmp"
        return 0
    fi

    # -----------------------------------------------------
    # Reescreve cabeçalhos de grupo para caminho absoluto
    # -----------------------------------------------------
    awk '
        $0 == "[/]" {
            print "[org/gnome/Ptyxis]"
            next
        }
        /^\[.*\]$/ {
            sub(/^\[/, "[org/gnome/Ptyxis/")
            print
            next
        }
        { print }
    ' "$dump_tmp" > "$rewritten_tmp"

    rm -f "$dump_tmp"

    local roots=("" "$JAIL_PATH")
    local root db_dir dconf_db_dir profile_dir
    local overall_ok=1

    for root in "${roots[@]}"; do

        local etc_dir="${root}/etc/dconf"
        db_dir="$etc_dir/db"
        dconf_db_dir="$db_dir/local.d"
        profile_dir="$etc_dir/profile"

        mkdir -p "$dconf_db_dir" "$profile_dir"

        if [[ ! -f "$profile_dir/user" ]]; then
            cat > "$profile_dir/user" <<'EOF'
user-db:user
system-db:local
EOF
        fi

        cp "$rewritten_tmp" "$dconf_db_dir/01-terminal-profile"

        if [[ -z "$root" ]]; then
            if dconf update; then
                echo "✅ Perfil de terminal aplicado no HOST."
            else
                echo "⚠️ Falha ao rodar 'dconf update' no HOST."
                overall_ok=0
            fi
        else
            if dconf update "$db_dir"; then
                echo "✅ Perfil de terminal aplicado na JAIL ($db_dir)."
            else
                echo "⚠️ Falha ao rodar 'dconf update' apontando para $db_dir"
                overall_ok=0
            fi
        fi
    done

    rm -f "$rewritten_tmp"

    if [[ "$overall_ok" -eq 1 ]]; then
        echo "✅ Perfil de terminal persistido (HOST + JAIL)."
    else
        echo "⚠️ Uma ou mais bases dconf não foram compiladas com sucesso."
        return 1
    fi
}

# =========================================================
# MAIN
# =========================================================

main() {

    validate_root
    validate_arguments
    validate_user
    confirm_replace
    prepare_skel

    copy_shell_configuration
    copy_user_directories
    copy_vscode_configuration

    configure_shared_ssh
    configure_gnome_template
    ensure_flatpak_in_jail

    install_gnome_extension_systemwide     
    configure_dconf_systemwide_extension
    configure_terminal_profile_systemwide
    remove_unwanted_content

    configure_permissions
    validate_result
    show_summary
}

main "$@"
