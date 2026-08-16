---
name: jail-container-win-configurations
description: Ambiente isolado utilizando Docker + WSL no Windows para interação segura com agentes de IA, reduzindo riscos de acesso indevido ao sistema operacional, arquivos pessoais e configurações do host.
---



# 🎯 Objetivos

O objetivo deste projeto é criar um ambiente controlado de desenvolvimento e execução de agentes de IA, permitindo que o acesso fique restrito apenas às pastas explicitamente compartilhadas.


* Isolar o ambiente de execução da IA do Windows
* Restringir acesso ao sistema operacional host
* Permitir acesso apenas às pastas compartilhadas
* Criar um ambiente seguro para automação e desenvolvimento
* Facilitar o uso de containers Docker com WSL
* Melhorar controle e previsibilidade do ambiente usado pelos agentes

---

# 🧱 Arquitetura

```text
Windows Host
│
├── WSL (Ubuntu)
│   │
│   ├── Usuário restrito (devjail)
│   │
│   ├── Workspace compartilhado
│   │
│   └── Docker
│       │
│       └── Containers isolados
│
└── VS Code + Dev Containers
```

---

# 🟢 Requisitos no Windows

## Opção 1 — Ativar recursos usando interface gráfica

1. Abra o menu iniciar
2. Pesquise por:

```text
Ativar ou desativar recursos do Windows
```

3. Habilite os seguintes recursos:

* Windows Subsystem for Linux
* Plataforma de Máquina Virtual
* Plataforma do Hipervisor do Windows

4. Clique em `OK`
5. Reinicie o computador

---

## Opção 2 — Ativar recursos usando PowerShell

Abra o PowerShell como Administrador:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart
```

Depois reinicie o computador.


---

## 2. Instalar o WSL

```powershell
wsl --install
```

---

## 3. Instalar Ubuntu pelo Microsoft Store

Instale:

* Ubuntu 22.04 LTS
* ou Ubuntu 24.04 LTS

Após instalar:

```powershell
wsl
```

---

## 4. Instalar Docker Desktop

Download oficial:

* https://www.docker.com/products/docker-desktop/

Durante a instalação:

* Habilite integração com WSL
* Habilite integração com Ubuntu

---

## 5. Instalar VS Code

Download oficial:

* https://code.visualstudio.com/download

Extensões recomendadas:

* Dev Containers
* Docker
* Remote - WSL

---

# 🟢 Configurando o Ubuntu no WSL

## 1. Acessar o Ubuntu via WSL

Abra o terminal do Windows e execute:
```powershell
wsl
```
Ou diretamente:
  ```powershell
  wsl -d Ubuntu
  ```

## 2. Atualizar sistema
```bash
sudo apt update && sudo apt upgrade -y
```

---

## 3. Criar usuário restrito

```bash
sudo adduser devjail
```

Não adicione permissões de sudo/root para este usuário.

---

## 4. Adicionar usuário ao grupo Docker

```bash
sudo usermod -aG docker devjail
```

---

# 🟢 Estrutura do Workspace

## 1. Criar diretório do workspace

```bash
mkdir -p /home/devjail/workspace
```

---

## 2. Compartilhar pasta do Windows

Exemplo:

```bash
sudo ln -s /mnt/c/Projetos /home/devjail/workspace
```

Agora somente esta pasta ficará disponível para o ambiente isolado.

---

# 🟢 Ajustando Permissões

## 1. Ajustar permissões do ambiente

```bash
sudo chown -R root:root /jail
sudo chmod 755 /jail
```

---

## 2. Ajustar permissões do workspace

```bash
sudo chown -R devjail:devjail /home/devjail/workspace
```

---

# 🟢 Criando Estrutura do Jail

## 1. Criar estrutura básica

```bash
sudo mkdir -p /jail/devjail/{bin,lib,lib64,home}
```

---

## 2. Copiar comandos básicos

```bash
sudo cp /bin/bash /jail/devjail/bin/
sudo cp /bin/ls /jail/devjail/bin/
sudo cp /bin/cat /jail/devjail/bin/
sudo cp /bin/pwd /jail/devjail/bin/
sudo cp /bin/echo /jail/devjail/bin/
```

Ou:

```bash
sudo cp /bin/{ls,cat,pwd,echo,bash} /jail/devjail/bin/
```

---

# 🟢 Entrando no Ambiente Isolado

## Entrar usando chroot

```bash
sudo chroot /jail/devjail /bin/bash
```

---

## Entrar usando usuário específico

Exemplo usando UID/GID:

```bash
sudo chroot --userspec=1001:1001 /jail/devjail /bin/bash
```

Outro exemplo:

```bash
sudo chroot --userspec=1003:1004 /jail/devjail /bin/bash
```

---

# 🟢 Utilizando Docker Dentro do Ambiente

Teste:

```bash
docker ps
```

Se funcionar corretamente, o usuário possui acesso controlado ao Docker sem permissões administrativas completas no Windows.

---

# 🟢 VS Code com WSL + Dev Containers

## Opção 1 — Abrir via terminal WSL

### 1. Acessar o Ubuntu via WSL

Abra o terminal do Windows:

```powershell
wsl
```

Ou diretamente:

```powershell
wsl -d Ubuntu
```

---

### 2. Entrar na pasta do projeto

```bash
cd /home/devjail/workspace
```

---

### 3. Abrir VS Code conectado ao WSL

```bash
code .
```

---

## Opção 2 — Abrir diretamente pelo VS Code

1. Abra o VS Code
2. Pressione `F1`
3. Execute:

```text
Remote-WSL: Connect to WSL
```

4. Escolha sua distribuição Ubuntu
5. Abra a pasta:

```text
/home/devjail/workspace
```

---

## 🟢 Abrir projeto no Dev Container

Após o VS Code estar conectado ao WSL:

1. Pressione `F1`
2. Execute:

```text
Dev Containers: Reopen in Container
```

---

### 🖥️ Acssar container

  > `docker exec -it ai-assistants-dev bash`


---

# 📌 Fluxo Correto

```text
Windows
   ↓
WSL (Ubuntu)
   ↓
VS Code Remote WSL
   ↓
Dev Container Docker
```

Este fluxo garante maior isolamento entre Windows, WSL e containers Docker.

---

# 🔒 Benefícios de Segurança

* Reduz acesso da IA ao Windows
* Restringe leitura de arquivos sensíveis
* Isola ferramentas e dependências
* Evita acesso ao sistema completo
* Permite destruir/recriar ambientes rapidamente
* Facilita auditoria do ambiente

---

# ⚠️ Limitações

Este modelo melhora isolamento, porém:

* Não substitui sandboxing completo
* Docker não é uma VM completa
* Containers ainda compartilham kernel Linux
* Montagens de volume precisam ser cuidadosamente controladas

Para isolamento mais forte considere:

* MicroVMs
* Firecracker
* Kata Containers
* Hyper-V isolado
* Ambientes totalmente virtuais

---

# 📌 Recomendações

* Compartilhe apenas diretórios necessários
* Nunca monte `C:\Users` inteiro
* Evite rodar containers privilegiados
* Utilize imagens mínimas
* Mantenha Docker e WSL atualizados
* Utilize usuários sem root sempre que possível

---
