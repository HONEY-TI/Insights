---
name: 🐳 docker-engine-ec2-installation
description: 📦 Instalação e configuração do Docker Engine + Docker Compose em instância EC2 Linux (Amazon Linux / RHEL-based), incluindo permissões de usuário, inicialização de serviço e autenticação no Docker Hub.
---

# 🐳 Install and Configure Docker Engine on EC2 Instance

## 🎯 Objetivo

Instalar e configurar o Docker Engine + Docker Compose em uma instância EC2 Linux garantindo:
- 📥 instalação via yum
- 👤 execução sem sudo
- ⚙️ inicialização automática no boot
- 🧩 suporte ao Docker Compose
- 🔐 login no Docker Hub

---

# 🧱 1. Atualizar sistema

sudo yum update -y

---

# 🔍 2. Buscar Docker

sudo yum search docker
sudo yum info docker

---

# 📦 3. Instalar Docker

sudo yum install docker -y

---

# 👤 4. Permitir usuário ec2-user usar Docker

sudo usermod -aG docker ec2-user
id ec2-user
newgrp docker

---

# ⚙️ 5. Ativar serviço no boot

sudo systemctl enable docker.service

---

# 🚀 6. Iniciar Docker

sudo systemctl start docker.service
sudo systemctl status docker.service

---

# 🧩 7. Instalar Docker Compose

## 📥 Download do binário

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

---

## 🔐 Permissão de execução

sudo chmod +x /usr/local/bin/docker-compose

---

## 🔎 Verificação

docker-compose --version

---

# 🔐 8. Login no Docker Hub

docker login -u <username> -p <token>

---

# 🧭 Fluxo final

📥 Update system  
🐳 Install Docker  
👤 Configure permissions  
⚙️ Enable service  
🚀 Start Docker  
🧩 Install Docker Compose  
🔐 Docker login