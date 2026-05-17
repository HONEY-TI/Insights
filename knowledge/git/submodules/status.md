---
name: git-submodules-status
description: Procedimentos operacionais, gerenciamento de ciclo de vida, sincronização, atualização e manutenção de Git Submodules dentro da arquitetura modular do workspace Insights. 
---


# 📌 Objetivo

## modules — Status de Todos os Submodules

Comandos para visualizar o status de todos os repositórios Git incluindo submodules.

---

# 🔍 Status do repositório principal

```bash
git status
```

---

# 🔍 Status de todos os submodules

```bash
git submodule foreach git status
```

---

# 📋 Status compacto de todos os submodules

```bash
git submodule foreach '
echo "----- $name -----"
git status --short --branch
echo
'
```

## Exemplo de saída

```text
----- prj-ai-assistants -----
## main...origin/main

----- prj-jail-container -----
## main
 M Dockerfile
```

---

# 🔄 Atualizar todos os submodules

## Atualizar para HEAD remoto configurado

```bash
git submodule update --remote
```

---

## Atualizar recursivamente

```bash
git submodule update --remote --recursive
```

---

# 🌿 Configurar submodule para seguir branch `main`

## Configurar `.gitmodules`

```bash
cd /Insights/projects
git config -f .gitmodules submodule.prj-ai-assistants.branch develop
git config -f .gitmodules submodule.prj-despesas-pessoais.branch develop
git config -f .gitmodules submodule.prj-infnet-lite-streaming.branch develop
git config -f .gitmodules submodule.prj-jail-container.branch develop
```

---

## Persistir configuração

```bash
git add .gitmodules
git commit -m "Configure submodules to track develop"
git push
```

---

# ➕ Adicionar submodule

```bash
git submodule add <URL_REPOSITORIO> <CAMINHO>
```

## Exemplo

```bash
git submodule add https://github.com/alexribeirofaria/prj-sistemas-web-.net-infnet.git prj-infnet-lite-streaming
```

---

# ❌ Remover submodule completamente

## 1. Desregistrar o submodule

```bash
git submodule deinit -f prj-infnet-lite-streaming
```

---

## 2. Remover do index do Git

```bash
git rm -f prj-infnet-lite-streaming
```

---

## 3. Remover cache interno do Git

```bash
rm -rf .git/modules/prj-infnet-lite-streaming
```

---

## 4. Remover entrada do `.gitmodules`

Remover bloco:

```ini
[submodule "prj-infnet-lite-streaming"]
    path = prj-infnet-lite-streaming
    url = https://github.com/alexribeirofaria/prj-sistemas-web-.net-infnet.git
```

---

## 5. Commit da remoção

```bash
git add .gitmodules
git commit -m "Remove submodule prj-infnet-lite-streaming"
git push
```

---

# 🧹 Verificar submodules existentes

```bash
git submodule status
```

---

# 🔁 Inicializar submodules após clone

```bash
git submodule update --init --recursive
```

---

# 🧠 Observações importantes

## Submodules sempre apontam para SHA

Mesmo configurando branch `main`, o Git sempre salva internamente um commit SHA específico no repositório principal.

O rastreamento de branch serve apenas para:

* atualizar automaticamente com `git submodule update --remote`
* facilitar sincronização
* evitar detached HEAD manual

---

# 🌿 Configurar Submodules para seguir branch `develop`

## 📌 Visão Geral

Por padrão, submodules sempre salvam um SHA específico do commit.

Para facilitar sincronização entre projetos, é possível configurar os submodules para rastrear automaticamente a branch `develop`.

---

# ⚙️ Configurar branch `develop` no `.gitmodules`

```bash
git config -f .gitmodules submodule.prj-ai-assistants.branch develop

git config -f .gitmodules submodule.prj-despesas-pessoais.branch develop

git config -f .gitmodules submodule.prj-infnet-lite-streaming.branch develop

git config -f .gitmodules submodule.prj-jail-container.branch develop
```

---

# 💾 Persistir configuração

```bash
git add .gitmodules
git commit -m "Configure submodules to track develop branch"
git push origin main
```

---

# 🔄 Trocar branch dentro dos submodules

```bash
git submodule foreach git checkout develop
```

---

# ⬆️ Atualizar todos os submodules para latest `develop`

```bash
git submodule update --remote
```

---

# 🔍 Validar configuração

```bash
cat .gitmodules
```

## Resultado esperado

```ini
[submodule "prj-ai-assistants"]
    path = prj-ai-assistants
    url = https://github.com/...
    branch = develop
```

---

# 🧠 Observações importantes

Mesmo configurando `develop`, o Git continua salvando internamente um SHA específico.

A configuração de branch serve para:

* atualizar automaticamente com `git submodule update --remote`
* evitar detached HEAD manual
* sincronizar módulos mais facilmente
* simplificar pipelines CI/CD

---

# 🚀 Fluxo recomendado

## Atualizar tudo para latest `develop`

```bash
git submodule foreach '
git checkout develop
git pull origin develop
'
```

Depois:

```bash
git add .
git commit -m "Update submodules to latest develop"
git push
```

---

# 🏗️ Estratégia recomendada para monorepo modular

| Ambiente   | Branch      |
| ---------- | ----------- |
| produção   | `main`      |
| integração | `develop`   |
| features   | `feature/*` |

---

# 🚀 Alias útil para visualizar status rapidamente

## Criar alias global

```bash
git config --global alias.substatus '!git submodule foreach '\''echo "----- $name -----"; git status --short --branch; echo'\'''
```

---

## Utilizar alias

```bash
git substatus
```

---


# ✅ Boas práticas

* manter todos os submodules na mesma branch (`develop`)
* usar `git submodule update --remote`
* evitar editar `.gitmodules` manualmente sem commit
* remover corretamente `.git/modules/...`
* utilizar `--recursive` em ambientes complexos
* evitar submodules aninhados desnecessários
