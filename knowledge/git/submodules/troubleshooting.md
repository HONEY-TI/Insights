---
name: troubleshooting-submodules
description: Soluções para inconsistências, conflitos e erros operacionais relacionados a submodules Git.
---

# 🔀 Git Submodules — Fluxo de Atualização, Conflito e Feature Branch

## 🔗 Relacionados

- [Git Integration Project](/knowledge/git/integration-project.md)
- [Sub Modules Life Cycle](/knowledge/git/submodules/lifecycle.md)
- [Sub Modules Procedimentos de Limpeza](/knowledge/git/submodules/cleanup.md)



## 🎯 Objetivo

Documentar o fluxo completo para trabalhar com **Git Submodules**, desde a atualização do projeto até a resolução de conflitos e criação de uma `feature/*` dentro do submodule.

Este processo contempla:

* 🔄 Atualização dos submodules
* 🔍 Identificação de conflitos
* 🛠️ Resolução de conflitos
* 💾 Criação do commit
* 🌿 Criação de uma `feature/*`
* 🚀 Push da feature
* 🔗 Atualização da referência do submodule no projeto principal

---

# 📚 1. Conceitos importantes

| Ícone | Conceito                    | Significado                                                     |
| ----- | --------------------------- | --------------------------------------------------------------- |
| 🏠    | **Projeto principal**       | Repositório que contém os submodules                            |
| 📦    | **Submodule**               | Outro repositório Git incorporado ao projeto                    |
| 🌿    | **Branch**                  | Linha independente de desenvolvimento                           |
| 🔀    | **Merge**                   | Combinação de históricos/alterações                             |
| ⚠️    | **Conflito**                | Git não conseguiu decidir automaticamente qual alteração manter |
| 📌    | **Commit**                  | Registro de um conjunto de alterações                           |
| 🚀    | **Push**                    | Envio dos commits para o repositório remoto                     |
| 🔗    | **Referência do submodule** | Commit específico do submodule que o projeto principal utiliza  |
| 🧩    | **Detached HEAD**           | Estado em que o Git está em um commit, mas não em uma branch    |
| 🔄    | **Update**                  | Atualização do estado dos submodules                            |

---

# 🏗️ 2. Estrutura

Exemplo do projeto:

```text
🏠 Insights
│
├── 📁 src/
│
├── 📦 projects/
│   ├── 📦 jail-container/
│   └── 📦 prj-despesas-pessoais/
│
└── 📄 .gitmodules
```

### 📌 Definição

Um **submodule** possui seu próprio repositório Git.

Por exemplo:

```text
🏠 Insights
    │
    └── 📦 prj-despesas-pessoais
            │
            ├── 🌿 main
            ├── 🌿 feature/devcontainer
            └── 📌 commits
```

O projeto `Insights` não armazena diretamente o histórico do submodule.

Ele armazena apenas uma **referência para um commit específico**.

---

# 🔄 3. Atualizar os Submodules

Entre no projeto principal:

```bash
cd ~/workspace/Insights
```

Atualize as informações do Git:

```bash
git fetch --all --prune
```

Inicialize e atualize os submodules:

```bash
git submodule update --init --recursive
```

Se for necessário forçar a atualização:

```bash
git submodule update --init --recursive --force
```

### 💡 Significado

```text
git submodule update
```

faz o projeto principal posicionar cada submodule no **commit registrado pelo projeto principal**.

---

# 🔍 4. Verificar o estado

Execute:

```bash
git submodule status
```

Exemplo:

```text
ad8c2f2 projects/jail-container
3fe2737 projects/prj-despesas-pessoais
```

Depois:

```bash
git status
```

### ✅ Resultado esperado

Nenhum conflito deve aparecer.

### ⚠️ Caso apareça:

```text
error: Merging is not possible because you have unmerged files.
```

significa que existe um conflito dentro de algum submodule.

---

# 🚨 5. Identificar o Submodule com Problema

Exemplo:

```text
fatal: Unable to merge '8eb214919655b1f1135541d333a63d62ad880362'
in submodule path 'projects/prj-despesas-pessoais'
```

### 📌 Significado

O problema está em:

```text
📦 projects/prj-despesas-pessoais
```

e **não diretamente no projeto `Insights`**.

Entre no submodule:

```bash
cd projects/prj-despesas-pessoais
```

---

# 🔍 6. Verificar os Conflitos

Execute:

```bash
git status
```

Pode aparecer:

```text
HEAD detached at 3fe2737f

Você tem caminhos não mesclados.
```

Para listar somente os arquivos conflitantes:

```bash
git diff --name-only --diff-filter=U
```

Para analisar o conflito:

```bash
git diff --cc
```

### ⚠️ Atenção

Não faça `git push` enquanto o submodule estiver com conflitos.

Primeiro:

```text
⚠️ Conflito
   ↓
🛠️ Resolver
   ↓
💾 Commit
   ↓
🌿 Criar Feature
   ↓
🚀 Push
```

---

# 🛠️ 7. Resolver os Conflitos

Existem três abordagens.

## 🟢 Opção 1 — Manter nossa versão

```bash
git checkout --ours -- .
git add -A
```

### 📌 Significado

Aceita a versão atual (`ours`) para os arquivos em conflito.

---

## 🔵 Opção 2 — Aceitar a versão deles

```bash
git checkout --theirs -- .
git add -A
```

### 📌 Significado

Aceita a versão recebida (`theirs`) para os arquivos em conflito.

---

## 🟡 Opção 3 — Resolver manualmente

Arquivos podem conter:

```text
<<<<<<< HEAD
conteúdo atual
=======
conteúdo recebido
>>>>>>> 8eb214919655b1f1135541d333a63d62ad880362
```

Escolha ou combine as alterações.

Depois:

```bash
git add -A
```

---

# ✅ 8. Confirmar a Resolução

Execute:

```bash
git status
```

A seção:

```text
Caminhos não mesclados:
```

não deve mais existir.

Também podemos confirmar:

```bash
git diff --name-only --diff-filter=U
```

### ✅ Resultado esperado

Nenhum arquivo retornado.

Isso significa:

```text
🛠️ Conflitos resolvidos
        ↓
📦 Submodule consistente
```

---

# 💾 9. Criar o Commit

Agora registre a resolução:

```bash
git commit
```

Exemplo:

```text
[b41ff969] Merge commit '8eb214919655b1f1135541d333a63d62ad880362' into HEAD
```

---

# 🧩 10. Resolver o Detached HEAD

Depois do commit, pode aparecer:

```text
HEAD detached at 3fe2737f
```

### 📌 O que significa?

O Git está apontando diretamente para um commit:

```text
📌 b41ff969
```

mas esse commit ainda não pertence a uma branch.

Visualmente:

```text
🌿 main
   │
   └── 📌 3fe2737

             📌 b41ff969
                  ↑
              HEAD aqui
              (detached)
```

### ⚠️ Não faça:

```bash
git push
```

porque você não está em uma branch.

---

# 🌿 11. Criar a Feature

Crie a branch diretamente a partir do commit atual:

```bash
git switch -c feature/devcontainer
```

### 📌 Padrão

```text
feature/<nome-da-feature>
```

Exemplos:

```text
feature/devcontainer
feature/docker-infra
feature/update-docker
feature/migrate-devcontainer
```

Neste caso:

```bash
git switch -c feature/devcontainer
```

Verifique:

```bash
git branch
```

Resultado:

```text
* feature/devcontainer
  main
```

### ✅ Agora o commit está protegido por uma branch.

---

# 🚀 12. Publicar a Feature

Envie a branch para o remoto:

```bash
git push -u origin feature/devcontainer
```

Resultado:

```text
📦 prj-despesas-pessoais

🌿 main
   │
   └── 📌 3fe2737

🌿 feature/devcontainer
   │
   └── 📌 b41ff969
```

No remoto:

```text
origin/main
origin/feature/devcontainer
```

---

# 🏠 13. Voltar para o Projeto Principal

Saia do submodule:

```bash
cd ../..
```

Agora estamos novamente em:

```text
~/workspace/Insights
```

Verifique:

```bash
git status
```

Pode aparecer:

```text
modified: projects/prj-despesas-pessoais (new commits)
```

### 📌 Por quê?

Porque o projeto principal anteriormente apontava para:

```text
📌 3fe2737
```

e agora o submodule está em:

```text
📌 b41ff969
```

O `Insights` precisa registrar essa nova referência.

---

# 🔗 14. Registrar a Nova Referência

No projeto principal:

```bash
git add projects/prj-despesas-pessoais
```

Verifique:

```bash
git status
```

Depois:

```bash
git commit -m "chore: update despesas pessoais submodule"
```

E envie:

```bash
git push
```

---

# 🔄 15. Fluxo Completo

```text
🏠 PROJETO PRINCIPAL
        │
        │ git fetch
        ▼
🔄 Atualizar Submodules
        │
        ▼
📦 Submodule
        │
        ├── ✅ Sem conflito
        │       │
        │       └── continuar
        │
        └── ⚠️ Conflito
                │
                ▼
        🔍 git status
                │
                ▼
        🛠️ Resolver conflito
                │
                ▼
        git add -A
                │
                ▼
        💾 git commit
                │
                ▼
        🧩 Detached HEAD?
                │
                ▼
        🌿 git switch -c feature/...
                │
                ▼
        🚀 git push -u origin feature/...
                │
                ▼
        🏠 Voltar ao projeto principal
                │
                ▼
        🔗 git add projects/...
                │
                ▼
        💾 git commit
                │
                ▼
        🚀 git push
```

---

# 📋 16. Comandos do Processo

## 🏠 Projeto principal

```bash
cd ~/workspace/Insights

git fetch --all --prune

git submodule update --init --recursive --force
```

## 📦 Submodule com conflito

```bash
cd projects/prj-despesas-pessoais

git status

git diff --name-only --diff-filter=U
```

### 🛠️ Resolver

```bash
# Resolver os arquivos

git add -A

git status

git commit
```

### 🌿 Criar Feature

```bash
git switch -c feature/devcontainer
```

### 🚀 Publicar Feature

```bash
git push -u origin feature/devcontainer
```

## 🏠 Projeto principal novamente

```bash
cd ../..

git status

git add projects/prj-despesas-pessoais

git commit -m "chore: update despesas pessoais submodule"

git push
```

---

# ⭐ 17. Regra Principal

> 🔑 **O conflito acontece dentro do submodule e deve ser resolvido dentro do submodule.**

O fluxo correto é:

```text
⚠️ Conflito
    ↓
📦 Entrar no Submodule
    ↓
🔍 Identificar arquivos
    ↓
🛠️ Resolver
    ↓
💾 Commit
    ↓
🌿 Criar feature/*
    ↓
🚀 Push da feature
    ↓
🏠 Voltar ao projeto principal
    ↓
🔗 Atualizar referência
    ↓
💾 Commit
    ↓
🚀 Push
```

---

# 🧠 18. Resumo dos Papéis

### 📦 Submodule

Responsável por:

* código;
* branches;
* conflitos;
* commits;
* feature branch;
* push da feature.

### 🏠 Projeto Principal

Responsável por:

* definir qual commit do submodule será utilizado;
* registrar a nova referência do submodule;
* fazer o commit dessa referência;
* publicar a atualização.

### 🔑 Regra mental

```text
📦 Submodule
    =
    código + branch + commit

🏠 Projeto principal
    =
    referência para o commit do submodule
```

Por isso, normalmente são necessários **dois commits/pushes**:

```text
📦 SUBMODULE
💾 Commit
🚀 Push
        │
        ▼
🏠 PROJETO PRINCIPAL
💾 Atualiza referência
🚀 Push
```
