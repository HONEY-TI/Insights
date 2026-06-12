#!/usr/bin/env bash

set -euo pipefail

# ==============================
# 🐳 Docker Clean Installer
#
# ⚙️ Tornar script executável
#  sudo chmod +x docker-install.sh
#do 
# ==============================

readonly DOCKER_GPG_DIR="/etc/apt/keyrings"
readonly DOCKER_GPG_KEY="${DOCKER_GPG_DIR}/docker.gpg"
readonly DOCKER_REPO_FILE="/etc/apt/sources.list.d/docker.list"

log() {
  echo -e "\n➡️  $1\n"
}

run() {
  echo "+ $*"
  eval "$@"
}

# ------------------------------
# 🧹 Remove old installations
# ------------------------------
remove_old_docker() {
  log "Removing old Docker installations..."

  run "sudo apt remove -y docker docker-engine docker.io containerd runc || true"
  run "sudo apt remove -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin || true"
  run "sudo snap remove docker 2>/dev/null || true"

  run "sudo apt autoremove -y"
  run "sudo apt autoclean"
}

# ------------------------------
# 📦 Install dependencies
# ------------------------------
install_dependencies() {
  log "Installing dependencies..."

  run "sudo apt update"
  run "sudo apt install -y ca-certificates curl gnupg"
}

# ------------------------------
# 🔐 Setup GPG key
# ------------------------------
setup_gpg() {
  log "Configuring Docker GPG key..."

  run "sudo install -m 0755 -d ${DOCKER_GPG_DIR}"

  run "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
       sudo gpg --dearmor -o ${DOCKER_GPG_KEY}"

  run "sudo chmod a+r ${DOCKER_GPG_KEY}"
}

# ------------------------------
# 📡 Setup repository
# ------------------------------
setup_repository() {
  log "Adding Docker repository..."

  run "echo \
  \"deb [arch=\$(dpkg --print-architecture) signed-by=${DOCKER_GPG_KEY}] \
  https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo \$VERSION_CODENAME) stable\" | \
  sudo tee ${DOCKER_REPO_FILE} > /dev/null"
}

# ------------------------------
# 🐳 Install Docker Engine
# ------------------------------
install_docker() {
  log "Installing Docker Engine + Compose..."

  run "sudo apt update"

  run "sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin"
}

# ------------------------------
# 🚀 Enable service
# ------------------------------
enable_docker() {
  log "Enabling Docker service..."

  run "sudo systemctl enable docker"
  run "sudo systemctl start docker"
}

# ------------------------------
# 👤 Configure user access
# ------------------------------
configure_user() {
  log "Adding user to docker group..."

  run "sudo usermod -aG docker \$USER"
}

# ------------------------------
# 🧪 Verify installation
# ------------------------------
verify() {
  log "Verifying installation..."

  run "docker --version || true"
  run "docker compose version || true"
}

# ------------------------------
# 🚀 Main execution
# ------------------------------
main() {
  remove_old_docker
  install_dependencies
  setup_gpg
  setup_repository
  install_docker
  enable_docker
  configure_user
  verify

  log "Installation complete!"
  echo "⚠️  Please logout/login to apply docker group changes."
}

main