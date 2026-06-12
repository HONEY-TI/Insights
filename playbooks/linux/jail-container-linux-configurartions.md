---
name: jail-container-linux-configurations
description: Ambiente isolado utilizando Docker com Linux para interação segura com agentes de IA, reduzindo riscos de acesso indevido ao sistema operacional, arquivos pessoais e configurações do host.
---


# 🐳 Instalação do Docker + Docker Compose no Ubuntu

## 📌 Visão geral

Este guia descreve a instalação do Docker Engine e do Docker Compose (v2 oficial) no Ubuntu segundo IA.

---

# 🧱 Step 1 — Remover versões antigas (opcional)

```bash
sudo apt remove -y docker docker-engine docker.io containerd runc
```

---

# 📦 Step 2 — Instalar dependências

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
```

---

# 🔐 Step 3 — Adicionar chave GPG do Docker

```bash
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

---

# 📡 Step 4 — Adicionar repositório oficial

```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

---

# 🐳 Step 5 — Instalar Docker Engine

```bash
sudo apt update

sudo apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin
```

---

# 🚀 Step 6 — Iniciar Docker

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

---

# 👤 Step 7 — Usar Docker sem sudo (opcional)

```bash
sudo usermod -aG docker $USER
```

Aplicar:

```bash
newgrp docker
```

---

# 🧪 Step 8 — Testar Docker

```bash
docker run hello-world
```

---

# 📦 Step 9 — Verificar Docker Compose (V2)

```bash
docker compose version
```

---

# ⚠️ IMPORTANTE

O Docker Compose moderno NÃO usa mais o comando separado `docker-compose`.

### ❌ Antigo (deprecated)

```bash
docker-compose --version
```

### ✅ Atual

```bash
docker compose version
```

---

# 🧠 Diferença entre versões

| Versão | Status | Comando        |
| ------ | ------ | -------------- |
| v1     | legado | docker-compose |
| v2     | atual  | docker compose |

---

# 🎯 Resultado final

Após a instalação você terá:

* Docker Engine funcionando
* Docker CLI configurado
* Docker Compose v2 integrado
* Sem necessidade de instalação manual adicional

---

# 🚀 Exemplos de uso

```bash
docker compose up -d
docker compose down
docker compose logs -f
```

---

# 🔒 Recomendação

Para ambientes modernos:

* Use Docker Compose v2 (plugin oficial)
* Evite instalação manual de binários antigos
