---
name: git-credential-manager-install
description: Instalação global do Git Credential Manager (GCM) com autenticação GitHub e suporte para JailKit
---

# 🔐 Instalação do Git Credential Manager + Integração GitHub

## 🎯 Objetivo

Este procedimento realiza a instalação e configuração global dos seguintes componentes:

- ✅ Git
- ✅ Git Credential Manager (GCM)
- ✅ GitHub CLI (`gh`)
- ✅ Autenticação HTTPS persistente
- ✅ Integração disponível para todos os usuários
- ✅ Compatibilidade com ambientes JailKit

---

# 🧱 1. Instalar Dependências

Atualize os repositórios e instale os pacotes necessários:

```bash
sudo apt update

sudo apt install -y \
    git \
    gh \
    curl \
    gpg \
    pass \
    wget
```

---

# 📦 2. Instalar o Git Credential Manager (GCM)

## 🔽 Definir versão

```bash
VERSION=2.6.1
```

## ⬇️ Baixar pacote oficial Linux

```bash
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v${VERSION}/gcm-linux_amd64.${VERSION}.deb
```

## ⚙️ Instalar pacote

```bash
sudo dpkg -i gcm-linux_amd64.${VERSION}.deb
```

## 🛠️ Corrigir dependências (caso necessário)

```bash
sudo apt --fix-broken install -y
```

---

# ⚙️ 3. Configurar o GCM Globalmente

## 🔐 Definir o GCM como helper padrão do Git

```bash
sudo git config --system credential.helper manager
```

## ☁️ Configurar armazenamento seguro de credenciais

```bash
sudo git config --system credential.credentialStore secretservice
```

```bash
git config --global user.name "Alex Ribeiro de Faria"
git config --global user.email "135660435+alexribeirofaria@github.com"

git config --system user.name "Alex Ribeiro de Faria"
git config --system user.email "135660435+alexribeirofaria@github.com"

```


---

# ✅ 4. Validar Instalação

Verifique se o GCM foi instalado corretamente:

```bash
git credential-manager version
```

---

# 👤 5. Realizar Login no GitHub

A autenticação é individual para cada usuário do sistema.

Cada usuário deverá executar um dos comandos abaixo:

## 🔑 Via GitHub CLI

```bash
gh auth login
```

## 🔐 Via Git Credential Manager

```bash
git credential-manager github login
```

---

# 🏗️ 6. Disponibilizar Binários Dentro do JailKit

Copie os binários necessários para a jail:

## 📁 Git

```bash
sudo jk_cp -j /home/jail $(which git)
```

## 📁 Git Credential Manager

```bash
sudo jk_cp -j /home/jail $(which git-credential-manager)
```

## 📁 GitHub CLI

```bash
sudo jk_cp -j /home/jail $(which gh)
```

---

# 🔍 7. Copiar Dependências Extras do GCM

O Git Credential Manager utiliza bibliotecas adicionais do .NET e dependências do sistema.

## 📋 Listar dependências

```bash
sudo ldd $(which git-credential-manager)
```

## ➕ Copiar bibliotecas ausentes para a jail

Caso alguma biblioteca esteja faltando dentro da jail:

```bash
sudo jk_cp -j /home/jail /caminho/da/lib.so
```

---

# 🧬 8. Inicializar Configuração Padrão no Skeleton

Crie uma configuração base para novos usuários:

## 📂 Criar estrutura padrão

```bash
sudo mkdir -p /home/skel-jail/.config/git
```

## ⚙️ Definir helper padrão do Git

```bash
sudo git config --file /home/skel-jail/.gitconfig credential.helper manager
```

---

# 🧪 9. Testar Funcionamento

Dentro da jail, execute:

```bash
git clone https://github.com/usuario/repositorio.git
```

## ✅ Resultado esperado

O Git Credential Manager deverá iniciar automaticamente o fluxo de autenticação HTTPS do GitHub.

---

# 📌 Observações Importantes

* 🔐 O login é armazenado por usuário.
* 🧰 O `gh` e o `GCM` podem coexistir sem conflitos.
* 🏢 A configuração via `--system` garante disponibilidade global.
* 🧱 Em ambientes JailKit, algumas bibliotecas podem precisar ser copiadas manualmente.
* 🚀 Recomendado para ambientes multiusuário e servidores DevOps.

---