---
name: git-config-skeleton-devcontainer
description: Configuração global do Git via /etc/skel com propagação para usuários da JailKit e Dev Containers Docker
---

# 🧩 Git Global — Skeleton e Dev Container

## 🎯 Objetivo

Garantir que novos usuários criados dentro da **JailKit** recebam automaticamente a identidade global do Git e que essa configuração também esteja disponível dentro dos **Dev Containers Docker**.

### Identidade configurada

- **Nome:** Alex Ribeiro de Faria
- **Email:** 135660435+alexribeirofaria@github.com

## 📁 1. Configuração no Skeleton

O arquivo principal deve existir em:

`/home/jail/etc/skel/.gitconfig`

Criar com:

    cat > /home/jail/etc/skel/.gitconfig <<'EOF'
    [user]
        name = Alex Ribeiro de Faria
        email = 135660435+alexribeirofaria@github.com
    EOF

Validar:

    cat /home/jail/etc/skel/.gitconfig

## 👤 2. Novos usuários

O `.gitconfig` do skeleton deve ser copiado automaticamente para o `$HOME` do novo usuário.

### Fluxo

    /home/jail/etc/skel/.gitconfig
            ↓
    criação do usuário
            ↓
    /home/jail/home/<usuario>/.gitconfig

Para usuários já existentes:

    cp /home/jail/etc/skel/.gitconfig \
       /home/jail/home/daniele-noeh/.gitconfig

    chown daniele-noeh:daniele-noeh \
       /home/jail/home/daniele-noeh/.gitconfig

## 🐳 3. Dev Container Docker

Dentro do Dev Container, o Git utiliza o `$HOME` do usuário.

Exemplo:

    $HOME=/home/node

Portanto, o arquivo esperado é:

    /home/node/.gitconfig

### Fluxo completo

    /home/jail/etc/skel/.gitconfig
                 ↓
          criação do usuário
                 ↓
    /home/jail/home/<usuario>/.gitconfig
                 ↓
           Dev Container
                 ↓
          /home/node/.gitconfig

## 🔍 4. Validação

Dentro do Dev Container:

    git config --global --get user.name
    git config --global --get user.email

Resultado esperado:

    Alex Ribeiro de Faria
    135660435+alexribeirofaria@github.com

Para verificar a origem da configuração:

    git config --list --show-origin --show-scope \
      | grep -E 'user.name|user.email'

O resultado ideal deve indicar:

    global  file:/home/node/.gitconfig

## ⚠️ 5. Configuração Local × Global

Evite configurar a identidade individualmente em cada repositório:

    git config user.name "..."
    git config user.email "..."

A configuração deve ser global:

    ~/.gitconfig

Configurações locais ficam em:

    .git/config

A configuração local tem prioridade sobre a configuração global.

## ✅ Resultado

Com o `.gitconfig` configurado no skeleton e propagado para o Dev Container:

- 👤 Novos usuários recebem a identidade automaticamente.
- 🐳 Novos Dev Containers recebem a configuração.
- 🔄 Não é necessário executar `git config --global` em cada projeto.
- 📦 A configuração fica centralizada no skeleton da JailKit.
