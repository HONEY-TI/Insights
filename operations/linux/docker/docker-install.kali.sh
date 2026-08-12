#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# 🐳 Docker Engine Installer - Kali Linux
#
# Instala:
#   - Docker Engine
#   - Docker CLI
#   - containerd
#   - Docker Buildx
#   - Docker Compose Plugin
#
# Configura:
#   - Repositório oficial Docker para Debian/Trixie
#   - Serviço Docker no systemd
#   - Usuário atual no grupo docker
#
# Uso:
#   chmod +x docker-install.sh
#   ./docker-install.sh
#
# ============================================================

readonly DOCKER_KEYRING_DIR="/etc/apt/keyrings"
readonly DOCKER_KEY="/etc/apt/keyrings/docker.asc"
readonly DOCKER_SOURCE="/etc/apt/sources.list.d/docker.sources"

log() {
    echo
    echo "============================================================"
    echo "➡️  $1"
    echo "============================================================"
    echo
}

die() {
    echo "❌ ERRO: $1" >&2
    exit 1
}

# ------------------------------------------------------------
# 🔐 Verificar root/sudo
# ------------------------------------------------------------

check_privileges() {
    log "Verificando privilégios"

    if ! command -v sudo >/dev/null 2>&1; then
        die "sudo não está instalado."
    fi

    sudo -v
}

# ------------------------------------------------------------
# 🐧 Verificar Kali Linux
# ------------------------------------------------------------

check_kali() {
    log "Verificando sistema"

    if [[ ! -f /etc/os-release ]]; then
        die "Não foi possível detectar o sistema operacional."
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    echo "Sistema: ${PRETTY_NAME:-desconhecido}"
    echo "Arquitetura: $(dpkg --print-architecture)"

    if [[ "${ID:-}" != "kali" ]]; then
        echo "⚠️  Aviso: este script foi desenvolvido especificamente para Kali Linux."
        echo "    Sistema detectado: ${PRETTY_NAME:-desconhecido}"
    fi

    if [[ "$(dpkg --print-architecture)" != "amd64" &&
          "$(dpkg --print-architecture)" != "arm64" &&
          "$(dpkg --print-architecture)" != "armhf" &&
          "$(dpkg --print-architecture)" != "ppc64el" ]]; then

        die "Arquitetura não suportada pelo repositório Docker."
    fi
}

# ------------------------------------------------------------
# 🧹 Remover pacotes conflitantes
# ------------------------------------------------------------

remove_conflicting_packages() {
    log "Removendo pacotes Docker conflitantes"

    sudo apt remove -y \
        docker.io \
        docker-compose \
        docker-compose-v2 \
        docker-doc \
        podman-docker \
        containerd \
        runc \
        docker-buildx \
        2>/dev/null || true
}

# ------------------------------------------------------------
# 📦 Dependências
# ------------------------------------------------------------

install_dependencies() {
    log "Instalando dependências"

    sudo apt update

    sudo apt install -y \
        ca-certificates \
        curl \
        gnupg
}

# ------------------------------------------------------------
# 🔐 Chave GPG oficial Docker
# ------------------------------------------------------------

setup_gpg() {
    log "Configurando chave GPG do Docker"

    sudo install \
        -m 0755 \
        -d "${DOCKER_KEYRING_DIR}"

    sudo rm -f "${DOCKER_KEY}"

    sudo curl \
        -fsSL \
        https://download.docker.com/linux/debian/gpg \
        -o "${DOCKER_KEY}"

    sudo chmod a+r "${DOCKER_KEY}"

    echo "✅ Chave GPG instalada em:"
    echo "   ${DOCKER_KEY}"
}

# ------------------------------------------------------------
# 📡 Repositório Docker para Debian Trixie
# ------------------------------------------------------------

setup_repository() {
    log "Configurando repositório oficial Docker"

    local architecture

    architecture="$(dpkg --print-architecture)"

    sudo tee "${DOCKER_SOURCE}" > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: ${architecture}
Signed-By: ${DOCKER_KEY}
EOF

    echo "✅ Repositório configurado:"
    cat "${DOCKER_SOURCE}"
}

# ------------------------------------------------------------
# 🐳 Instalar Docker Engine
# ------------------------------------------------------------

install_docker() {
    log "Instalando Docker Engine"

    sudo apt update

    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
}

# ------------------------------------------------------------
# 🚀 Habilitar Docker
# ------------------------------------------------------------

enable_docker() {
    log "Habilitando serviço Docker"

    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    sudo systemctl start docker.service

    if ! sudo systemctl is-active --quiet docker; then
        die "O serviço Docker não iniciou corretamente."
    fi

    echo "✅ Docker está ativo."
}

# ------------------------------------------------------------
# 👤 Configurar usuário atual
# ------------------------------------------------------------

configure_user() {
    log "Configurando acesso do usuário ao Docker"

    if ! getent group docker >/dev/null 2>&1; then
        sudo groupadd docker
    fi

    sudo usermod -aG docker "${USER}"

    echo "✅ Usuário '${USER}' adicionado ao grupo docker."
}

# ------------------------------------------------------------
# 🧪 Verificar instalação
# ------------------------------------------------------------

verify_installation() {
    log "Verificando instalação"

    echo "Docker:"
    docker --version

    echo
    echo "Docker Compose:"
    docker compose version

    echo
    echo "Docker Buildx:"
    docker buildx version

    echo
    echo "Serviço:"
    sudo systemctl --no-pager --full status docker | head -n 15
}

# ------------------------------------------------------------
# 🧪 Teste hello-world
# ------------------------------------------------------------

test_docker() {
    log "Executando teste Docker"

    echo "⚠️  A sessão atual pode ainda não reconhecer o grupo docker."
    echo "    Tentando executar o teste usando sudo..."

    sudo docker run --rm hello-world
}

# ------------------------------------------------------------
# 🧹 Limpeza
# ------------------------------------------------------------

cleanup() {
    log "Limpando arquivos temporários"

    sudo apt autoremove -y
    sudo apt autoclean
}

# ------------------------------------------------------------
# 🚀 Main
# ------------------------------------------------------------

main() {

    log "🐳 Docker Clean Installer - Kali Linux"

    check_privileges
    check_kali

    remove_conflicting_packages
    install_dependencies
    setup_gpg
    setup_repository
    install_docker
    enable_docker
    configure_user
    verify_installation
    test_docker
    cleanup

    log "✅ INSTALAÇÃO CONCLUÍDA"

    echo "Docker:"
    docker --version

    echo
    echo "Docker Compose:"
    docker compose version

    echo
    echo "Usuário:"
    echo "${USER}"

    echo
    echo "⚠️  IMPORTANTE:"
    echo "   Saia da sessão e entre novamente para usar Docker sem sudo."
    echo
    echo "   Depois teste:"
    echo "   docker run hello-world"
    echo
}

main "$@"